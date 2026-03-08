#!/usr/bin/env Rscript
#' =====================================================================
#' DC ISAs コード高度評価 - Deep Learning & Machine Learning 統合
#' =====================================================================
#' Deep Learning と Machine Learning を用いた DC ISAs のコード評価
#' GitHub LLM が Deep な DC ISAs や ISAs である高度コード化の場合の R 表現
#' =====================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(caret)
  library(randomForest)
  library(xgboost)
  library(keras)
  library(tensorflow)
  library(ggplot2)
})

print("=" %*% 80)
print("DC ISAs コード高度評価 - Deep Learning & Machine Learning 統合")
print("=" %*% 80)
print("")

# =====================================================================
# SECTION 1: DC ISAs データセットの準備
# =====================================================================
print("SECTION 1: DC ISAs データセットの準備")
print("─" %*% 70)

# DC ISAs のコードメトリクスをシミュレート
set.seed(2026)
n_samples <- 1000

dc_isa_metrics <- tibble(
  isa_name = paste0("DC_ISA_", 1:n_samples),
  code_complexity = rnorm(n_samples, mean = 50, sd = 15),
  instruction_count = rpois(n_samples, lambda = 1000),
  branch_density = runif(n_samples, 0, 1),
  memory_access_pattern = rnorm(n_samples, mean = 0.5, sd = 0.2),
  power_consumption = rnorm(n_samples, mean = 100, sd = 20),
  execution_time = rnorm(n_samples, mean = 10, sd = 3),
  cache_miss_rate = runif(n_samples, 0, 0.1),
  scalability_score = runif(n_samples, 0, 10),
  # ターゲット: コード高度評価スコア (0-100)
  code_quality_score = round(
    50 +
    0.3 * code_complexity +
    0.1 * instruction_count +
    -20 * branch_density +
    10 * memory_access_pattern +
    -0.2 * power_consumption +
    -0.5 * execution_time +
    -50 * cache_miss_rate +
    2 * scalability_score +
    rnorm(n_samples, 0, 5)
  ) %>% pmax(0) %>% pmin(100)
)

print(sprintf("✓ DC ISAs データセット生成: %dサンプル", nrow(dc_isa_metrics)))
print(sprintf("  特徴量: %d個", ncol(dc_isa_metrics) - 2))  # isa_name と target を除く
print("")

# =====================================================================
# SECTION 2: データ前処理
# =====================================================================
print("SECTION 2: データ前処理")
print("─" %*% 70)

# 特徴量とターゲットの分離
features <- dc_isa_metrics %>%
  select(-isa_name, -code_quality_score) %>%
  as.matrix()

target <- dc_isa_metrics$code_quality_score

# データ分割 (訓練:80%, テスト:20%)
set.seed(2026)
train_index <- createDataPartition(target, p = 0.8, list = FALSE)
X_train <- features[train_index, ]
X_test <- features[-train_index, ]
y_train <- target[train_index]
y_test <- target[-train_index]

print(sprintf("✓ データ分割完了: 訓練 %dサンプル, テスト %dサンプル", nrow(X_train), nrow(X_test)))
print("")

# =====================================================================
# SECTION 3: Machine Learning モデル - Random Forest
# =====================================================================
print("SECTION 3: Machine Learning モデル - Random Forest")
print("─" %*% 70)

# Random Forest モデルの訓練
rf_model <- randomForest(
  x = X_train,
  y = y_train,
  ntree = 100,
  mtry = floor(sqrt(ncol(X_train))),
  importance = TRUE
)

# 予測と評価
rf_predictions <- predict(rf_model, X_test)
rf_rmse <- sqrt(mean((rf_predictions - y_test)^2))
rf_r2 <- cor(rf_predictions, y_test)^2

print(sprintf("✓ Random Forest モデル訓練完了"))
print(sprintf("  RMSE: %.2f, R²: %.2f", rf_rmse, rf_r2))

# 特徴量重要度
rf_importance <- importance(rf_model)
print("  特徴量重要度 (トップ5):")
top_features <- head(sort(rf_importance[,1], decreasing = TRUE), 5)
for (i in seq_along(top_features)) {
  cat(sprintf("    %d. %s: %.2f\n", i, names(top_features)[i], top_features[i]))
}
print("")

# =====================================================================
# SECTION 4: Deep Learning モデル - Neural Network
# =====================================================================
print("SECTION 4: Deep Learning モデル - Neural Network")
print("─" %*% 70)

# データ正規化
X_train_scaled <- scale(X_train)
X_test_scaled <- scale(X_test, center = attr(X_train_scaled, "scaled:center"),
                       scale = attr(X_train_scaled, "scaled:scale"))

# Keras モデルの構築
model <- keras_model_sequential() %>%
  layer_dense(units = 64, activation = 'relu', input_shape = ncol(X_train)) %>%
  layer_dropout(rate = 0.2) %>%
  layer_dense(units = 32, activation = 'relu') %>%
  layer_dropout(rate = 0.2) %>%
  layer_dense(units = 16, activation = 'relu') %>%
  layer_dense(units = 1)  # 回帰なので1ユニット

# モデルコンパイル
model %>% compile(
  loss = 'mean_squared_error',
  optimizer = optimizer_adam(learning_rate = 0.001),
  metrics = c('mean_absolute_error')
)

# モデル訓練
history <- model %>% fit(
  X_train_scaled, y_train,
  epochs = 100,
  batch_size = 32,
  validation_split = 0.2,
  verbose = 0
)

# 予測と評価
dl_predictions <- predict(model, X_test_scaled)
dl_rmse <- sqrt(mean((dl_predictions - y_test)^2))
dl_r2 <- cor(dl_predictions, y_test)^2

print(sprintf("✓ Deep Learning モデル訓練完了"))
print(sprintf("  RMSE: %.2f, R²: %.2f", dl_rmse, dl_r2))
print("")

# =====================================================================
# SECTION 5: XGBoost モデル - Gradient Boosting
# =====================================================================
print("SECTION 5: XGBoost モデル - Gradient Boosting")
print("─" %*% 70)

# XGBoost モデルの訓練
xgb_model <- xgboost(
  data = X_train,
  label = y_train,
  nrounds = 100,
  objective = "reg:squarederror",
  max_depth = 6,
  eta = 0.1,
  verbose = 0
)

# 予測と評価
xgb_predictions <- predict(xgb_model, X_test)
xgb_rmse <- sqrt(mean((xgb_predictions - y_test)^2))
xgb_r2 <- cor(xgb_predictions, y_test)^2

print(sprintf("✓ XGBoost モデル訓練完了"))
print(sprintf("  RMSE: %.2f, R²: %.2f", xgb_rmse, xgb_r2))

# 特徴量重要度
xgb_importance <- xgb.importance(model = xgb_model)
print("  特徴量重要度 (トップ5):")
if (nrow(xgb_importance) > 0) {
  top_xgb <- head(xgb_importance, 5)
  for (i in 1:nrow(top_xgb)) {
    cat(sprintf("    %d. %s: %.2f\n", i, top_xgb$Feature[i], top_xgb$Gain[i]))
  }
}
print("")

# =====================================================================
# SECTION 6: モデル比較と評価
# =====================================================================
print("SECTION 6: モデル比較と評価")
print("─" %*% 70)

# モデル性能比較
model_comparison <- tibble(
  Model = c("Random Forest", "Deep Learning", "XGBoost"),
  RMSE = c(rf_rmse, dl_rmse, xgb_rmse),
  R2 = c(rf_r2, dl_r2, xgb_r2)
)

print("モデル性能比較:")
for (i in 1:nrow(model_comparison)) {
  row <- model_comparison[i, ]
  cat(sprintf("  %s: RMSE = %.2f, R² = %.2f\n", row$Model, row$RMSE, row$R2))
}

# 最適モデル選択
best_model <- model_comparison %>% arrange(RMSE) %>% slice(1)
print(sprintf("\n✓ 最適モデル: %s (RMSE: %.2f)", best_model$Model, best_model$RMSE))
print("")

# =====================================================================
# SECTION 7: DC ISAs コード評価の予測
# =====================================================================
print("SECTION 7: DC ISAs コード評価の予測")
print("─" %*% 70)

# 新しい ISA の評価例
new_isa <- matrix(c(
  60,    # code_complexity
  1200,  # instruction_count
  0.3,   # branch_density
  0.7,   # memory_access_pattern
  90,    # power_consumption
  8,     # execution_time
  0.05,  # cache_miss_rate
  8      # scalability_score
), nrow = 1)

# 各モデルの予測
rf_pred <- predict(rf_model, new_isa)
dl_pred_scaled <- predict(model, scale(new_isa, center = attr(X_train_scaled, "scaled:center"),
                                      scale = attr(X_train_scaled, "scaled:scale")))
xgb_pred <- predict(xgb_model, new_isa)

print("新しい DC ISA のコード品質予測:")
cat(sprintf("  Random Forest: %.1f\n", rf_pred))
cat(sprintf("  Deep Learning: %.1f\n", dl_pred_scaled))
cat(sprintf("  XGBoost: %.1f\n", xgb_pred))
cat(sprintf("  平均予測: %.1f\n", mean(c(rf_pred, dl_pred_scaled, xgb_pred))))
print("")

# =====================================================================
# SECTION 8: 可視化と分析
# =====================================================================
print("SECTION 8: 可視化と分析")
print("─" %*% 70)

# 予測 vs 実測値の散布図データ
prediction_data <- tibble(
  Actual = y_test,
  Random_Forest = rf_predictions,
  Deep_Learning = as.vector(dl_predictions),
  XGBoost = xgb_predictions
)

print("✓ 予測データ準備完了")
print("")

# =====================================================================
# SECTION 9: DC ISAs 高度コード化の評価指標
# =====================================================================
print("SECTION 9: DC ISAs 高度コード化の評価指標")
print("─" %*% 70)

# 高度コード化の評価指標
code_quality_metrics <- dc_isa_metrics %>%
  mutate(
    quality_category = case_when(
      code_quality_score >= 80 ~ "Excellent",
      code_quality_score >= 60 ~ "Good",
      code_quality_score >= 40 ~ "Average",
      TRUE ~ "Poor"
    ),
    complexity_efficiency = code_quality_score / code_complexity,
    performance_efficiency = scalability_score / execution_time
  ) %>%
  group_by(quality_category) %>%
  summarise(
    count = n(),
    avg_score = mean(code_quality_score),
    avg_complexity = mean(code_complexity),
    avg_execution_time = mean(execution_time),
    avg_scalability = mean(scalability_score),
    .groups = "drop"
  )

print("コード品質カテゴリ別統計:")
for (i in 1:nrow(code_quality_metrics)) {
  row <- code_quality_metrics[i, ]
  cat(sprintf("  %s: %d個 (平均スコア: %.1f)\n",
              row$quality_category, row$count, row$avg_score))
}
print("")

# =====================================================================
# SECTION 10: 出力ファイルの生成
# =====================================================================
print("SECTION 10: 出力ファイルの生成")
print("─" %*% 70)

output_dir <- "analysis_output"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# 1. DC ISAs データセット
write_csv(dc_isa_metrics, file.path(output_dir, "dc_isa_dataset.csv"))
cat("✓ dc_isa_dataset.csv 生成\n")

# 2. モデル比較結果
write_csv(model_comparison, file.path(output_dir, "model_comparison.csv"))
cat("✓ model_comparison.csv 生成\n")

# 3. 予測結果
write_csv(prediction_data, file.path(output_dir, "prediction_results.csv"))
cat("✓ prediction_results.csv 生成\n")

# 4. コード品質メトリクス
write_csv(code_quality_metrics, file.path(output_dir, "code_quality_metrics.csv"))
cat("✓ code_quality_metrics.csv 生成\n")

# 5. 特徴量重要度 (Random Forest)
rf_importance_df <- as.data.frame(rf_importance) %>%
  rownames_to_column(var = "feature")
write_csv(rf_importance_df, file.path(output_dir, "rf_feature_importance.csv"))
cat("✓ rf_feature_importance.csv 生成\n")

# 6. XGBoost 特徴量重要度
if (exists("xgb_importance") && nrow(xgb_importance) > 0) {
  write_csv(xgb_importance, file.path(output_dir, "xgb_feature_importance.csv"))
  cat("✓ xgb_feature_importance.csv 生成\n")
}

print("")

# =====================================================================
# SECTION 11: 最終サマリーレポート
# =====================================================================
print("SECTION 11: 最終サマリーレポート")
print("─" %*% 70)

summary_report <- list(
  dataset_size = nrow(dc_isa_metrics),
  features_count = ncol(features),
  models_trained = 3,
  best_model = best_model$Model,
  best_rmse = best_model$RMSE,
  output_files = 6,
  quality_categories = nrow(code_quality_metrics),
  ml_techniques = c("Random Forest", "Deep Learning (Neural Network)", "XGBoost")
)

cat("DC ISAs コード高度評価 ML/DL 統合サマリー:\n")
cat(sprintf("  データセット: %dサンプル × %d特徴量\n", summary_report$dataset_size, summary_report$features_count))
cat(sprintf("  訓練モデル: %d種類 (%s)\n", summary_report$models_trained, paste(summary_report$ml_techniques, collapse = ", ")))
cat(sprintf("  最適モデル: %s (RMSE: %.2f)\n", summary_report$best_model, summary_report$best_rmse))
cat(sprintf("  品質カテゴリ: %d種類\n", summary_report$quality_categories))
cat(sprintf("  出力ファイル: %d個\n", summary_report$output_files))
print("")

# =====================================================================
# SECTION 12: GitHub LLM 高度コード化の推奨
# =====================================================================
print("SECTION 12: GitHub LLM 高度コード化の推奨")
print("─" %*% 70)

# GitHub LLM 向けのコード品質推奨
llm_recommendations <- tibble::tribble(
  ~aspect, ~recommendation, ~rationale,
  "コード複雑度", "最適化された複雑度維持", "高すぎると保守性が低下、低すぎると機能不足",
  "命令数", "効率的な命令使用", "無駄な命令を避け、性能を最適化",
  "分岐密度", "分岐の最小化", "分岐が多いと予測ミスが増加",
  "メモリアクセス", "局所性重視", "キャッシュ効率を最大化",
  "消費電力", "エネルギー効率", "データセンターでの運用コスト削減",
  "実行時間", "高速化", "応答性とスループットの向上",
  "キャッシュミス", "ミス率低減", "メモリレイテンシーの削減",
  "スケーラビリティ", "高いスケーラビリティ", "大規模システム対応"
)

print("GitHub LLM 向けコード品質推奨:")
for (i in 1:nrow(llm_recommendations)) {
  row <- llm_recommendations[i, ]
  cat(sprintf("  %s: %s\n    理由: %s\n", row$aspect, row$recommendation, row$rationale))
}
print("")

write_csv(llm_recommendations, file.path(output_dir, "llm_recommendations.csv"))
cat("✓ llm_recommendations.csv 生成\n")

print("")
print("=" %*% 80)
print("✅ 完了: DC ISAs コード高度評価 - Deep Learning & Machine Learning 統合")
print("=" %*% 80)
print("")
print("生成されたファイル:")
print("  - dc_isa_dataset.csv           : DC ISAs データセット")
print("  - model_comparison.csv         : モデル性能比較")
print("  - prediction_results.csv       : 予測結果")
print("  - code_quality_metrics.csv     : コード品質統計")
print("  - rf_feature_importance.csv    : Random Forest 特徴量重要度")
print("  - xgb_feature_importance.csv   : XGBoost 特徴量重要度")
print("  - llm_recommendations.csv      : LLM 推奨事項")
print("")
print("すべてのファイルは analysis_output/ ディレクトリに保存されています")
print("")
print("R での ML/DL 表現:")
print("  - Random Forest: randomForest パッケージ")
print("  - Deep Learning: keras/tensorflow パッケージ")
print("  - XGBoost: xgboost パッケージ")
print("  - 評価指標: RMSE, R², 特徴量重要度")
print("")
