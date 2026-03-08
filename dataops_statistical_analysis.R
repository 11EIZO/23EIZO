#!/usr/bin/env Rscript
#' =====================================================================
#' DataOps Metric 統計分析・可視化スクリプト
#' =====================================================================
#' メトリクス間の相関分析、分布分析、トレンド分析を実施
#' Created: 2026-03-08
#' =====================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(ggplot2)
  library(corrplot)
})

print("=" %*% 70)
print("DataOps Metric 統計分析・可視化フェーズ")
print("=" %*% 70)
print("")

output_dir <- "analysis_output"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# =====================================================================
# SECTION 1: 統合メトリクスデータの読み込み
# =====================================================================
print("SECTION 1: データの読み込み")
print("─" %*% 70)

base_data <- read_csv("processor_execution_data.csv", show_col_types = FALSE)
summary_metrics <- read_csv("analysis_output/summary_metrics.csv", show_col_types = FALSE)

print(sprintf("✓ 基本データセット: %d行 × %d列", nrow(base_data), ncol(base_data)))
print(sprintf("✓ サマリーメトリクス: %d行 × %d列", nrow(summary_metrics), ncol(summary_metrics)))
print("")

# =====================================================================
# SECTION 2: ワークロード別メトリクス統計
# =====================================================================
print("SECTION 2: ワークロード別メトリクス統計")
print("─" %*% 70)

workload_stats <- summary_metrics %>%
  group_by(workload) %>%
  summarise(
    across(where(is.numeric) & !contains("samples"),
           list(
             mean = ~mean(., na.rm = TRUE),
             sd = ~sd(., na.rm = TRUE),
             min = ~min(., na.rm = TRUE),
             max = ~max(., na.rm = TRUE)
           ),
           .names = "{.col}_{.fn}")
  ) %>%
  pivot_longer(
    cols = -workload,
    names_to = "metric_stat",
    values_to = "value"
  ) %>%
  separate(metric_stat, c("metric", "statistic"), sep = "_(?=[a-z]+$)")

write_csv(workload_stats, file.path(output_dir, "workload_stats.csv"))
print(sprintf("✓ ワークロード別統計: %d行", nrow(workload_stats)))
print("")

# =====================================================================
# SECTION 3: メトリクス間相関分析
# =====================================================================
print("SECTION 3: メトリクス間相関分析")
print("─" %*% 70)

# 数値メトリクスのみを抽出
numeric_metrics <- summary_metrics %>%
  select(-workload, -core, -samples) %>%
  as.matrix()

# 相関マトリックスを計算
correlation_matrix <- cor(numeric_metrics, use = "complete.obs")

# 相関マトリックスをデータフレームに変換
cor_df <- correlation_matrix %>%
  as.data.frame() %>%
  rownames_to_column(var = "metric1") %>%
  pivot_longer(
    cols = -metric1,
    names_to = "metric2",
    values_to = "correlation"
  ) %>%
  filter(metric1 < metric2) %>%  # 重複を除去
  arrange(desc(abs(correlation)))

write_csv(cor_df, file.path(output_dir, "correlation_analysis.csv"))
print(sprintf("✓ メトリクス相関分析: %d ペア", nrow(cor_df)))

# 高相関を抽出
high_correlation <- cor_df %>%
  filter(abs(correlation) > 0.7)
print(sprintf("  高相関 (|r| > 0.7): %d ペア", nrow(high_correlation)))
print("")

# =====================================================================
# SECTION 4: パフォーマンス特性の分析
# =====================================================================
print("SECTION 4: パフォーマンス特性の分析")
print("─" %*% 70)

# ワークロード別のパフォーマンスランキング
performance_ranking <- summary_metrics %>%
  select(workload, core, execution_time_mean, ipc_mean, cache_miss_rate_mean) %>%
  group_by(workload) %>%
  summarise(
    avg_execution_time = mean(execution_time_mean),
    avg_ipc = mean(ipc_mean),
    avg_cache_miss_rate = mean(cache_miss_rate_mean),
    .groups = "drop"
  ) %>%
  arrange(avg_execution_time) %>%
  mutate(
    execution_rank = row_number(),
    ipc_rank = rank(desc(avg_ipc)),
    efficiency_rank = rank(desc(avg_ipc)) + rank(cache_miss_rate_mean)  # 総合効率
  )

write_csv(performance_ranking, file.path(output_dir, "performance_ranking.csv"))
print(sprintf("✓ パフォーマンスランキング: %d ワークロード", nrow(performance_ranking)))

# ランキング表示
cat("\nワークロード別実行時間ランキング:\n")
for (i in seq_len(nrow(performance_ranking))) {
  row <- performance_ranking[i, ]
  cat(sprintf("  %d. %s (%.2fs, IPC: %.2f, キャッシュミスレート: %.2f%%)\n",
              row$execution_rank,
              row$workload,
              row$avg_execution_time,
              row$avg_ipc,
              row$avg_cache_miss_rate * 100))
}
print("")

# =====================================================================
# SECTION 5: 効率指標の計算
# =====================================================================
print("SECTION 5: 効率指標の計算")
print("─" %*% 70)

# CPI/IPCに基づく効率スコア
efficiency_metrics <- summary_metrics %>%
  mutate(
    # IPC正規化 (0-1, 高いほど良い)
    ipc_normalized = (ipc_mean - min(ipc_mean)) / (max(ipc_mean) - min(ipc_mean)),
    
    # キャッシュミス正規化 (0-1, 低いほど良い)
    cache_efficiency = 1 - (cache_miss_rate_mean - min(cache_miss_rate_mean)) / 
                          (max(cache_miss_rate_mean) - min(cache_miss_rate_mean)),
    
    # 複合効率スコア (0-10)
    efficiency_score = (ipc_normalized + cache_efficiency) * 5,
    
    # パフォーマンス効率 (命令数/実行時間)
    performance_efficiency = instructions_mean / execution_time_mean / 1e9  # GIPS
  ) %>%
  select(workload, core, ipc_normalized, cache_efficiency, efficiency_score, performance_efficiency)

write_csv(efficiency_metrics, file.path(output_dir, "efficiency_metrics.csv"))
print(sprintf("✓ 効率指標計算完了: %d行", nrow(efficiency_metrics)))
print("")

# =====================================================================
# SECTION 6: コア間の性能差異分析
# =====================================================================
print("SECTION 6: コア間の性能差異分析")
print("─" %*% 70)

core_variance <- summary_metrics %>%
  group_by(workload) %>%
  summarise(
    execution_time_delta = max(execution_time_mean) - min(execution_time_mean),
    ipc_delta = max(ipc_mean) - min(ipc_mean),
    cache_delta = max(cache_miss_rate_mean) - min(cache_miss_rate_mean),
    imbalance_ratio = (max(execution_time_mean) - min(execution_time_mean)) / 
                      min(execution_time_mean) * 100,
    .groups = "drop"
  ) %>%
  arrange(desc(imbalance_ratio))

write_csv(core_variance, file.path(output_dir, "core_variance_analysis.csv"))
print(sprintf("✓ コア間差異分析: %d ワークロード", nrow(core_variance)))

cat("\nコア間不均衡率:\n")
for (i in seq_len(nrow(core_variance))) {
  row <- core_variance[i, ]
  cat(sprintf("  %s: %.2f%%\n", row$workload, row$imbalance_ratio))
}
print("")

# =====================================================================
# SECTION 7: メトリクスの集約統計
# =====================================================================
print("SECTION 7: メトリクスの集約統計")
print("─" %*% 70)

metric_aggregates <- summary_metrics %>%
  select(-workload, -core, -samples) %>%
  summarise(
    across(everything(),
           list(
             overall_mean = ~mean(., na.rm = TRUE),
             overall_sd = ~sd(., na.rm = TRUE),
             overall_cv = ~sd(., na.rm = TRUE) / mean(., na.rm = TRUE) * 100  # 変動係数
           ),
           .names = "{.col}_{.fn}")
  ) %>%
  pivot_longer(
    everything(),
    names_to = "metric_stat",
    values_to = "value"
  ) %>%
  separate(metric_stat, c("metric", "statistic"), sep = "_(?=[a-z]+$)")

write_csv(metric_aggregates, file.path(output_dir, "metric_aggregates.csv"))
print(sprintf("✓ メトリクス集約統計: %d行", nrow(metric_aggregates)))
print("")

# =====================================================================
# SECTION 8: ワークロード分類と特性
# =====================================================================
print("SECTION 8: ワークロード分類と特性")
print("─" %*% 70)

workload_characteristics <- summary_metrics %>%
  group_by(workload) %>%
  summarise(
    # 実行時間による分類
    execution_time = mean(execution_time_mean),
    
    # 命令数による分類
    instruction_count = mean(instructions_mean) / 1e9,
    
    # 効率による分類
    ipc = mean(ipc_mean),
    cache_miss = mean(cache_miss_rate_mean) * 100,
    
    # 分類カテゴリ
    workload_category = case_when(
      mean(execution_time_mean) < 1.0 ~ "Light",
      mean(execution_time_mean) < 2.0 ~ "Medium",
      TRUE ~ "Heavy"
    ),
    
    efficiency_category = case_when(
      mean(ipc_mean) < 1.2 ~ "Low IPC",
      mean(ipc_mean) < 1.4 ~ "Medium IPC",
      TRUE ~ "High IPC"
    ),
    
    .groups = "drop"
  ) %>%
  arrange(execution_time)

write_csv(workload_characteristics, file.path(output_dir, "workload_characteristics.csv"))
print(sprintf("✓ ワークロード特性分析: %d ワークロード", nrow(workload_characteristics)))

cat("\nワークロード分類:\n")
for (i in seq_len(nrow(workload_characteristics))) {
  row <- workload_characteristics[i, ]
  cat(sprintf("  %s: %s, %s (exec: %.2fs, IPC: %.2f, cache miss: %.2f%%)\n",
              row$workload,
              row$workload_category,
              row$efficiency_category,
              row$execution_time,
              row$ipc,
              row$cache_miss))
}
print("")

# =====================================================================
# SECTION 9: データ品質レポート
# =====================================================================
print("SECTION 9: データ品質レポート")
print("─" %*% 70)

data_quality_report <- tibble::tibble(
  Dataset = c("base_data", "summary_metrics", "total"),
  Rows = c(nrow(base_data), nrow(summary_metrics), nrow(base_data) + nrow(summary_metrics)),
  Columns = c(ncol(base_data), ncol(summary_metrics), NA),
  Missing_Values = c(
    sum(is.na(base_data)),
    sum(is.na(summary_metrics)),
    sum(is.na(base_data)) + sum(is.na(summary_metrics))
  ),
  Completeness = c(
    (1 - sum(is.na(base_data)) / (nrow(base_data) * ncol(base_data))) * 100,
    (1 - sum(is.na(summary_metrics)) / (nrow(summary_metrics) * ncol(summary_metrics))) * 100,
    NA
  )
)

write_csv(data_quality_report, file.path(output_dir, "data_quality_report.csv"))
print(sprintf("✓ データ品質レポート生成完了"))

cat("\n")
for (i in seq_len(nrow(data_quality_report) - 1)) {
  row <- data_quality_report[i, ]
  cat(sprintf("  %s: %.1f%% 完全性 (%d行 × %d列)\n",
              row$Dataset,
              row$Completeness,
              row$Rows,
              row$Columns))
}
print("")

# =====================================================================
# SECTION 10: 最終分析サマリー
# =====================================================================
print("SECTION 10: 最終分析サマリー")
print("─" %*% 70)

analysis_summary <- tibble::tibble(
  Analysis = c(
    "ワークロード別統計",
    "メトリクス相関分析",
    "パフォーマンスランキング",
    "効率指標計算",
    "コア間差異分析",
    "メトリクス集約統計",
    "ワークロード特性分析",
    "データ品質レポート"
  ),
  Records = c(
    nrow(workload_stats),
    nrow(cor_df),
    nrow(performance_ranking),
    nrow(efficiency_metrics),
    nrow(core_variance),
    nrow(metric_aggregates),
    nrow(workload_characteristics),
    nrow(data_quality_report)
  ),
  Status = "✓ Complete"
)

write_csv(analysis_summary, file.path(output_dir, "analysis_summary.csv"))
print("")
for (i in seq_len(nrow(analysis_summary))) {
  row <- analysis_summary[i, ]
  cat(sprintf("  ✓ %s (%d レコード)\n", row$Analysis, row$Records))
}

print("")
print("=" %*% 70)
print("✅ 統計分析フェーズ完了")
print("=" %*% 70)
print("")
print("生成されたレポート:")
print("  - workload_stats.csv           : ワークロード別統計")
print("  - correlation_analysis.csv     : メトリクス相関分析")
print("  - performance_ranking.csv      : パフォーマンスランキング")
print("  - efficiency_metrics.csv       : 効率指標")
print("  - core_variance_analysis.csv   : コア間差異分析")
print("  - metric_aggregates.csv        : 集約統計")
print("  - workload_characteristics.csv : ワークロード特性")
print("  - data_quality_report.csv      : データ品質レポート")
print("  - analysis_summary.csv         : 分析サマリー")
print("")
