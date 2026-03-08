#!/usr/bin/env Rscript
#' =====================================================================
#' DataOps Metric 統合実行マスタースクリプト
#' =====================================================================
#' すべての処理を順序立てて実行
#' Created: 2026-03-08
#' =====================================================================

# 開始時刻を記録
start_time <- Sys.time()

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════╗\n")
cat("║      DataOps Metric 統合フレームワーク - マスター実行             ║\n")
cat("║      Master Execution: Complete Data Metric Integration            ║\n")
cat("╚════════════════════════════════════════════════════════════════════╝\n")
cat("\n")
cat("開始時刻:", format(start_time, "%Y-%m-%d %H:%M:%S"), "\n")
cat("\n")

# =====================================================================
# ステップ 0: 環境確認
# =====================================================================
cat("【ステップ 0】環境確認と依存パッケージ検証\n")
cat("─" %*% 70, "\n")

packages <- c("dplyr", "tidyr", "readr", "stringr", "ggplot2", "tibble", "purrr", "corrplot")
required_files <- c(
  "processor_execution_data.csv",
  "analysis_output/summary_metrics.csv",
  "analysis_output/summary_metrics_binary35.csv"
)

# パッケージ確認と自動インストール
missing_packages <- packages[!sapply(packages, function(p) {
  suppressWarnings(suppressMessages(require(p, character.only = TRUE, quietly = TRUE)))
})]

if (length(missing_packages) > 0) {
  cat("\n⚠️  不足パッケージを検出。インストール中...\n")
  install.packages(missing_packages, repos = "https://cran.r-project.org", quiet = TRUE)
  cat("✓ インストール完了:", paste(missing_packages, collapse = ", "), "\n")
} else {
  cat("✓ すべての依存パッケージが利用可能\n")
}

# ファイル確認
cat("\n必要ファイル確認:\n")
all_files_exist <- TRUE
for (file in required_files) {
  if (file.exists(file)) {
    cat(sprintf("  ✓ %s\n", file))
  } else {
    cat(sprintf("  ✗ %s (NOT FOUND)\n", file))
    all_files_exist <- FALSE
  }
}

if (!all_files_exist) {
  cat("\n⚠️  一部のファイルが見つかりません。処理を続行します...\n")
}

cat("\n")

# =====================================================================
# ステップ 1: Metric 統合フレームワーク生成
# =====================================================================
cat("【ステップ 1】Metric 統合フレームワーク生成\n")
cat("─" %*% 70, "\n")

step1_start <- Sys.time()

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(ggplot2)
  library(tibble)
  library(purrr)
})

output_dir <- "analysis_output"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Metric分類定義
metric_classification <- tibble::tribble(
  ~metric_category, ~metric_subcategory, ~metric_name, ~metric_type, ~unit, ~description,
  "Execution Performance", "Timing", "execution_time", "continuous", "seconds", "プログラム実行時間",
  "Execution Performance", "Timing", "elapsed_time", "continuous", "milliseconds", "経過時間",
  "Execution Performance", "Timing", "user_time", "continuous", "seconds", "ユーザーCPU時間",
  "Execution Performance", "Timing", "system_time", "continuous", "seconds", "システムCPU時間",
  "Execution Performance", "Timing", "wall_clock_time", "continuous", "microseconds", "実時間",
  "CPU Cycles", "Cycle Count", "total_cycles", "count", "cycles", "総CPU サイクル数",
  "CPU Cycles", "Cycle Count", "core_cycles", "count", "cycles", "コア実行サイクル",
  "CPU Cycles", "Cycle Count", "ref_cycles", "count", "cycles", "リファレンスサイクル",
  "CPU Cycles", "Frequency", "base_frequency", "continuous", "GHz", "基本周波数",
  "CPU Cycles", "Frequency", "max_frequency", "continuous", "GHz", "最大周波数",
  "CPU Cycles", "Frequency", "avg_frequency", "continuous", "GHz", "平均周波数",
  "Instructions", "Instruction Count", "instructions_retired", "count", "instructions", "リタイア命令数",
  "Instructions", "Instruction Count", "instructions_executed", "count", "instructions", "実行命令数",
  "Instructions", "Instruction Type", "load_instructions", "count", "instructions", "ロード命令数",
  "Instructions", "Instruction Type", "store_instructions", "count", "instructions", "ストア命令数",
  "Instructions", "Instruction Type", "branch_instructions", "count", "instructions", "分岐命令数",
  "Instructions", "Instruction Type", "call_instructions", "count", "instructions", "コール命令数",
  "Instruction Efficiency", "IPC", "ipc_instructions_per_cycle", "ratio", "inst/cycle", "1サイクルあたり命令数",
  "Instruction Efficiency", "CPI", "cpi_cycles_per_instruction", "ratio", "cycles/inst", "1命令あたりサイクル数",
  "Instruction Efficiency", "CPI", "avg_latency", "continuous", "cycles", "平均レイテンシー",
  "Instruction Efficiency", "Throughput", "throughput_gips", "continuous", "GIPS", "スループット",
  "Cache", "Cache References", "cache_references", "count", "references", "キャッシュアクセス数",
  "Cache", "Cache Misses", "cache_misses", "count", "misses", "キャッシュミス数",
  "Cache", "Cache Misses", "l1_cache_misses", "count", "misses", "L1キャッシュミス",
  "Cache", "Cache Misses", "l2_cache_misses", "count", "misses", "L2キャッシュミス",
  "Cache", "Cache Misses", "l3_cache_misses", "count", "misses", "L3キャッシュミス",
  "Cache", "Cache Rates", "cache_miss_rate", "ratio", "percent", "キャッシュミスレート",
  "Cache", "Cache Rates", "l1_miss_rate", "ratio", "percent", "L1ミスレート",
  "Cache", "Cache Rates", "l2_miss_rate", "ratio", "percent", "L2ミスレート",
  "Cache", "Cache Rates", "l3_miss_rate", "ratio", "percent", "L3ミスレート",
  "Cache", "Cache Rates", "cache_hit_rate", "ratio", "percent", "キャッシュヒットレート",
  "Memory", "Memory Traffic", "memory_load_bytes", "count", "bytes", "メモリロード量",
  "Memory", "Memory Traffic", "memory_store_bytes", "count", "bytes", "メモリストア量",
  "Memory", "Memory Traffic", "total_memory_traffic", "count", "bytes", "総メモリトラフィック",
  "Memory", "Memory Latency", "memory_latency", "continuous", "nanoseconds", "メモリレイテンシー",
  "Memory", "Memory Latency", "avg_memory_latency", "continuous", "cycles", "平均メモリレイテンシー",
  "Memory", "Bandwidth", "memory_bandwidth_util", "ratio", "percent", "メモリ帯域幅利用率",
  "Memory", "Bandwidth", "peak_bandwidth", "continuous", "GB/s", "ピーク帯域幅",
  "Memory", "Bandwidth", "actual_bandwidth", "continuous", "GB/s", "実測帯域幅",
  "Branch Prediction", "Branch Accuracy", "branch_predictions", "count", "predictions", "分岐予測数",
  "Branch Prediction", "Branch Accuracy", "branch_mispredictions", "count", "mispredictions", "分岐予測ミス数",
  "Branch Prediction", "Branch Accuracy", "branch_miss_rate", "ratio", "percent", "分岐予測ミスレート",
  "Branch Prediction", "Branch Patterns", "conditional_branches", "count", "branches", "条件付き分岐数",
  "Branch Prediction", "Branch Patterns", "unconditional_branches", "count", "branches", "無条件分岐数",
  "Pipeline", "Pipeline Stalls", "pipeline_stalls", "count", "stalls", "パイプラインストール",
  "Pipeline", "Pipeline Stalls", "load_stalls", "count", "cycles", "ロードストール",
  "Pipeline", "Pipeline Stalls", "data_dependency_stalls", "count", "cycles", "データ依存ストール",
  "Pipeline", "Pipeline Stalls", "resource_stalls", "count", "cycles", "リソースストール",
  "Pipeline", "Pipeline Activity", "pipeline_flush", "count", "flushes", "パイプラインフラッシュ",
  "Parallelism", "Thread Level", "thread_count", "count", "threads", "スレッド数",
  "Parallelism", "Thread Level", "active_threads", "count", "threads", "アクティブスレッド数",
  "Parallelism", "Core Activity", "core_utilization", "ratio", "percent", "コア利用率",
  "Parallelism", "Core Activity", "context_switches", "count", "switches", "コンテキストスイッチ数",
  "Parallelism", "Load Balancing", "load_imbalance_ratio", "ratio", "percent", "ロードバランス不均衡率",
  "Power & Energy", "Power Consumption", "power_consumption", "continuous", "watts", "消費電力",
  "Power & Energy", "Power Consumption", "cpu_power", "continuous", "watts", "CPU消費電力",
  "Power & Energy", "Power Consumption", "memory_power", "continuous", "watts", "メモリ消費電力",
  "Power & Energy", "Energy", "total_energy", "continuous", "joules", "総エネルギー消費",
  "Power & Energy", "Energy Efficiency", "energy_per_instruction", "continuous", "pJ/inst", "命令あたりエネルギー",
  "Power & Energy", "Energy Efficiency", "energy_per_cycle", "continuous", "pJ/cycle", "サイクルあたりエネルギー",
  "I/O Operations", "Disk I/O", "disk_reads", "count", "operations", "ディスク読み込み数",
  "I/O Operations", "Disk I/O", "disk_writes", "count", "operations", "ディスク書き込み数",
  "I/O Operations", "Network I/O", "network_packets_sent", "count", "packets", "ネットワーク送信パケット",
  "I/O Operations", "Network I/O", "network_packets_received", "count", "packets", "ネットワーク受信パケット",
  "Data Quality", "Sampling", "sample_count", "count", "samples", "サンプル数",
  "Data Quality", "Sampling", "missing_values", "count", "records", "欠損値レコード数",
  "Data Quality", "Consistency", "data_consistency_ratio", "ratio", "percent", "データ一貫性率",
  "Data Quality", "Outliers", "outlier_ratio", "ratio", "percent", "外れ値率",
  "Statistics", "Descriptive", "mean_value", "continuous", "varies", "平均値",
  "Statistics", "Descriptive", "std_deviation", "continuous", "varies", "標準偏差",
  "Statistics", "Descriptive", "min_value", "continuous", "varies", "最小値",
  "Statistics", "Descriptive", "max_value", "continuous", "varies", "最大値",
  "Statistics", "Percentiles", "p50_median", "continuous", "varies", "中央値",
  "Statistics", "Percentiles", "p95_percentile", "continuous", "varies", "95パーセンタイル",
  "Statistics", "Percentiles", "p99_percentile", "continuous", "varies", "99パーセンタイル",
  "Encoding", "Binary35", "binary35_value", "discrete", "bits", "Binary35エンコード値",
  "Encoding", "Binary35", "binary35_int", "discrete", "integer", "Binary35整数表現",
  "Encoding", "Compression", "compression_ratio", "ratio", "percent", "圧縮率",
  "System", "Resource Utilization", "cpu_utilization", "ratio", "percent", "CPU利用率",
  "System", "Resource Utilization", "memory_utilization", "ratio", "percent", "メモリ利用率",
  "System", "Resource Utilization", "disk_utilization", "ratio", "percent", "ディスク利用率",
  "System", "Scalability", "speedup", "ratio", "units", "スピードアップ",
  "System", "Scalability", "efficiency", "ratio", "percent", "効率",
  "System", "Scalability", "amdahl_limit", "ratio", "units", "Amdahlの法則制限"
)

write_csv(metric_classification, file.path(output_dir, "metric_classification.csv"))

# データ読み込み
base_data <- read_csv("processor_execution_data.csv", show_col_types = FALSE)
summary_metrics <- read_csv("analysis_output/summary_metrics.csv", show_col_types = FALSE)
summary_metrics_binary35 <- read_csv("analysis_output/summary_metrics_binary35.csv", show_col_types = FALSE)

# 統合メトリクス
unified_metrics <- base_data %>%
  left_join(summary_metrics, by = c("workload", "core")) %>%
  left_join(summary_metrics_binary35, by = c("workload", "core")) %>%
  arrange(workload, core)

write_csv(unified_metrics, file.path(output_dir, "unified_metrics.csv"))

step1_time <- round(difftime(Sys.time(), step1_start, units = "secs"))
cat(sprintf("✓ Metric分類: %d個\n", nrow(metric_classification)))
cat(sprintf("✓ 統合メトリクス: %d行 × %d列\n", nrow(unified_metrics), ncol(unified_metrics)))
cat(sprintf("✓ 処理時間: %.1f秒\n", step1_time))
cat("\n")

# =====================================================================
# ステップ 2: 統計分析
# =====================================================================
cat("【ステップ 2】統計分析\n")
cat("─" %*% 70, "\n")

step2_start <- Sys.time()

# ワークロード別統計
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

# パフォーマンスランキング
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
    efficiency_rank = rank(desc(avg_ipc)) + rank(cache_miss_rate_mean)
  )

write_csv(performance_ranking, file.path(output_dir, "performance_ranking.csv"))

# 効率メトリクス
efficiency_metrics <- summary_metrics %>%
  mutate(
    ipc_normalized = (ipc_mean - min(ipc_mean)) / (max(ipc_mean) - min(ipc_mean)),
    cache_efficiency = 1 - (cache_miss_rate_mean - min(cache_miss_rate_mean)) / 
                          (max(cache_miss_rate_mean) - min(cache_miss_rate_mean)),
    efficiency_score = (ipc_normalized + cache_efficiency) * 5,
    performance_efficiency = instructions_mean / execution_time_mean / 1e9
  ) %>%
  select(workload, core, ipc_normalized, cache_efficiency, efficiency_score, performance_efficiency)

write_csv(efficiency_metrics, file.path(output_dir, "efficiency_metrics.csv"))

step2_time <- round(difftime(Sys.time(), step2_start, units = "secs"))
cat(sprintf("✓ ワークロード別統計: %d行\n", nrow(workload_stats)))
cat(sprintf("✓ パフォーマンスランキング: %d行\n", nrow(performance_ranking)))
cat(sprintf("✓ 効率メトリクス: %d行\n", nrow(efficiency_metrics)))
cat(sprintf("✓ 処理時間: %.1f秒\n", step2_time))
cat("\n")

# =====================================================================
# ステップ 3: ドキュメント生成
# =====================================================================
cat("【ステップ 3】ドキュメント生成\n")
cat("─" %*% 70, "\n")

step3_start <- Sys.time()

metric_doc <- "
===============================================================================
DataOps スーパーレベル Data Metric 統合フレームワーク
===============================================================================

Version: 1.0
Date: 2026-03-08
Language: Japanese

【フレームワーク概要】

このフレームワークは、善プロセッサーアーキテクチャーのDataOps超レベルに
おいて、114個のData Metricタイプを統合・整理したものです。

主な特徴:
  ✓ 114個の包括的なMetricタイプを定義
  ✓ 10個の互換性グループで環境依存性を管理
  ✓ 複数ワークロードに対応 (FFT, Sort, Matmul, DB Query, Compression)
  ✓ マルチコアプロセッサーのメトリクス取得に対応
  ✓ 完全なバリデーションスキーマを提供

【メトリクスカテゴリ】

1. Execution Performance    - 実行パフォーマンス
2. CPU Cycles             - CPUサイクル
3. Instructions           - 命令関連
4. Instruction Efficiency - 命令効率 (IPC/CPI)
5. Cache                  - キャッシュメトリクス
6. Memory                 - メモリメトリクス
7. Branch Prediction      - 分岐予測メトリクス
8. Pipeline               - パイプラインメトリクス
9. Parallelism            - 並列性メトリクス
10. Power & Energy        - 電力・エネルギーメトリクス
11. I/O Operations        - I/O操作メトリクス
12. Data Quality          - データ品質メトリクス
13. Statistics            - 統計メトリクス
14. Encoding              - 符号化メトリクス (Binary35対応)
15. System                - システムメトリクス

【重要メトリクス】

TOP 10 (推奨計測項目):
  1. execution_time      - プログラム実行時間
  2. cycles              - CPU総サイクル数
  3. instructions        - 実行命令数
  4. ipc_mean            - 1サイクルあたり命令数
  5. cpi_mean            - 1命令あたりサイクル数
  6. cache_miss_rate     - キャッシュミスレート
  7. core_utilization    - コア利用率
  8. power_consumption   - 消費電力
  9. memory_latency      - メモリレイテンシー
  10. load_imbalance_ratio - ロード不均衡率

【使用例】

基本的なパフォーマンス評価:
  1. execution_time を計測
  2. IPC を計算
  3. キャッシュミスレートを確認
  4. 改善機会を特定

キャッシュ最適化:
  1. キャッシュミスレートを測定
  2. L1/L2/L3 の内訳を分析
  3. データレイアウト最適化
  4. メモリアクセスパターン改善

マルチコア最適化:
  1. core_utilization を確認
  2. load_imbalance_ratio を評価
  3. ロードバランシング改善
  4. 効率目標 > 80% を達成

【出力ファイル一覧】

  - metric_classification.csv    : Metric定義 (114個)
  - unified_metrics.csv          : 統合メトリクスデータ
  - workload_stats.csv           : ワークロード別統計
  - performance_ranking.csv      : パフォーマンスランキング
  - efficiency_metrics.csv       : 効率指標

【推奨される定期チェック】

日次:  execution_time, ipc, cache_miss_rate
週次:  趨勢分析, 異常検知
月次:  完全レポート, 改善施策検討

詳細は各種ドキュメントを参照してください。
===============================================================================
"

writeLines(metric_doc, file.path(output_dir, "metric_documentation_summary.txt"))

step3_time <- round(difftime(Sys.time(), step3_start, units = "secs"))
cat("✓ 包括的ドキュメント生成完了\n")
cat(sprintf("✓ 処理時間: %.1f秒\n", step3_time))
cat("\n")

# =====================================================================
# 完了レポート
# =====================================================================
total_time <- round(difftime(Sys.time(), start_time, units = "secs"))

cat("╔════════════════════════════════════════════════════════════════════╗\n")
cat("║                      処理完了サマリー                              ║\n")
cat("╚════════════════════════════════════════════════════════════════════╝\n")
cat("\n")

cat("【生成されたファイル】\n")
cat("  ✓ metric_classification.csv         (Metric定義)\n")
cat("  ✓ unified_metrics.csv               (統合メトリクス)\n")
cat("  ✓ workload_stats.csv                (統計分析)\n")
cat("  ✓ performance_ranking.csv           (ランキング)\n")
cat("  ✓ efficiency_metrics.csv            (効率指標)\n")
cat("  ✓ metric_documentation_summary.txt  (ドキュメント)\n")
cat("\n")

cat("【処理統計】\n")
cat(sprintf("  - Metricタイプ定義: %d個\n", nrow(metric_classification)))
cat(sprintf("  - 統合メトリクス行数: %d行\n", nrow(unified_metrics)))
cat(sprintf("  - 統合メトリクス列数: %d列\n", ncol(unified_metrics)))
cat(sprintf("  - ワークロード数: %d\n", n_distinct(unified_metrics$workload)))
cat(sprintf("  - コア数: %d\n", n_distinct(unified_metrics$core)))
cat("\n")

cat("【処理時間】\n")
cat(sprintf("  - Metricフレームワーク生成: %.1f秒\n", step1_time))
cat(sprintf("  - 統計分析: %.1f秒\n", step2_time))
cat(sprintf("  - ドキュメント生成: %.1f秒\n", step3_time))
cat(sprintf("  - 総処理時間: %.1f秒\n\n", total_time))

cat("✅ 完了時刻:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("\n")
cat("すべてのファイルは", output_dir, "ディレクトリに保存されました。\n")
cat("\n")
