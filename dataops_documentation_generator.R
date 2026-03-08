#!/usr/bin/env Rscript
#' =====================================================================
#' DataOps Metric ドキュメント生成スクリプト
#' =====================================================================
#' 包括的なメトリクス参考資料とユーザーガイドを生成
#' Created: 2026-03-08
#' =====================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

print("=" %*% 70)
print("DataOps Metric ドキュメント生成フェーズ")
print("=" %*% 70)
print("")

output_dir <- "analysis_output"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# =====================================================================
# メトリクス定義ドキュメント生成
# =====================================================================
print("ドキュメント生成中...")
print("─" %*% 70)
print("")

# Metricドキュメント本体
metric_doc <- "
================================================================================
DataOps スーパーレベル Data Metric 統合フレームワーク
包括的メトリクス参考資料
================================================================================

Version: 1.0
Date: 2026-03-08
Language: Japanese

================================================================================
目次
================================================================================

1. 概要
2. メトリクス体系
3. メトリクスカテゴリ詳細
4. 互換性グループ
5. 測定方法と単位
6. データバリデーション
7. 使用ガイドライン
8. よくある質問 (FAQ)

================================================================================
1. 概要
================================================================================

本フレームワークは、善プロセッサーアーキテクチャーのDataOps超レベルにおいて、
すべての関連Data Metricを統合・整理したものです。

主な特徴:
  ✓ 114個の包括的なMetricタイプを定義
  ✓ 10個の互換性グループで環境依存性を管理
  ✓ 複数ワークロード（FFT, Sort, Matrix Multiply, DB Query, Compression）に対応
  ✓ マルチコアプロセッサーのメトリクス取得に対応
  ✓ 完全なバリデーションスキーマを提供

================================================================================
2. メトリクス体系
================================================================================

メトリクスは以下の10個の主カテゴリで分類されています:

2.1 Execution Performance（実行パフォーマンス）
    └─ Timing: 実行時間関連メトリクス
       - execution_time        : プログラム実行時間
       - elapsed_time          : 経過時間
       - user_time             : ユーザーCPU時間
       - system_time           : システムCPU時間
       - wall_clock_time       : 実時間

2.2 CPU Cycles（CPUサイクル）
    ├─ Cycle Count: サイクル数関連
    │  - total_cycles         : 総CPU サイクル数
    │  - core_cycles          : コア実行サイクル
    │  - ref_cycles           : リファレンスサイクル
    └─ Frequency: 周波数関連
       - base_frequency       : 基本周波数
       - max_frequency        : 最大周波数
       - avg_frequency        : 平均周波数

2.3 Instructions（命令関連）
    ├─ Instruction Count: 命令数
    │  - instructions_retired : リタイア命令数
    │  - instructions_executed: 実行命令数
    └─ Instruction Type: 命令タイプ
       - load_instructions    : ロード命令数
       - store_instructions   : ストア命令数
       - branch_instructions  : 分岐命令数
       - call_instructions    : コール命令数

2.4 Instruction Efficiency（命令効率）
    ├─ IPC: 命令/サイクル
    │  - ipc_instructions_per_cycle: 1サイクルあたり命令数
    ├─ CPI: サイクル/命令
    │  - cpi_cycles_per_instruction: 1命令あたりサイクル数
    │  - avg_latency                : 平均レイテンシー
    └─ Throughput: スループット
       - throughput_gips: スループット (GIPS)

2.5 Cache（キャッシュ）
    ├─ Cache References: キャッシュアクセス
    │  - cache_references    : キャッシュアクセス数
    ├─ Cache Misses: キャッシュミス
    │  - cache_misses        : キャッシュミス数
    │  - l1_cache_misses     : L1キャッシュミス
    │  - l2_cache_misses     : L2キャッシュミス
    │  - l3_cache_misses     : L3キャッシュミス
    └─ Cache Rates: キャッシュレート
       - cache_miss_rate     : キャッシュミスレート
       - l1_miss_rate        : L1ミスレート
       - l2_miss_rate        : L2ミスレート
       - l3_miss_rate        : L3ミスレート
       - cache_hit_rate      : キャッシュヒットレート

2.6 Memory（メモリ）
    ├─ Memory Traffic: メモリトラフィック
    │  - memory_load_bytes   : メモリロード量
    │  - memory_store_bytes  : メモリストア量
    │  - total_memory_traffic: 総メモリトラフィック
    ├─ Memory Latency: メモリレイテンシー
    │  - memory_latency      : メモリレイテンシー
    │  - avg_memory_latency  : 平均メモリレイテンシー
    └─ Bandwidth: 帯域幅
       - memory_bandwidth_util: メモリ帯域幅利用率
       - peak_bandwidth      : ピーク帯域幅
       - actual_bandwidth    : 実測帯域幅

2.7 Branch Prediction（分岐予測）
    ├─ Branch Accuracy: 予測精度
    │  - branch_predictions  : 分岐予測数
    │  - branch_mispredictions: 分岐予測ミス数
    │  - branch_miss_rate    : 分岐予測ミスレート
    └─ Branch Patterns: 分岐パターン
       - conditional_branches: 条件付き分岐数
       - unconditional_branches: 無条件分岐数

2.8 Pipeline（パイプライン）
    ├─ Pipeline Stalls: パイプラインストール
    │  - pipeline_stalls          : パイプラインストール
    │  - load_stalls              : ロードストール
    │  - data_dependency_stalls   : データ依存ストール
    │  - resource_stalls          : リソースストール
    └─ Pipeline Activity: パイプライン活動
       - pipeline_flush: パイプラインフラッシュ

2.9 Parallelism（並列性）
    ├─ Thread Level: スレッドレベル
    │  - thread_count        : スレッド数
    │  - active_threads      : アクティブスレッド数
    ├─ Core Activity: コア活動
    │  - core_utilization    : コア利用率
    │  - context_switches    : コンテキストスイッチ数
    └─ Load Balancing: ロードバランシング
       - load_imbalance_ratio: ロードバランス不均衡率

2.10 Power & Energy（電力・エネルギー）
     ├─ Power Consumption: 消費電力
     │  - power_consumption: 消費電力
     │  - cpu_power       : CPU消費電力
     │  - memory_power    : メモリ消費電力
     ├─ Energy: エネルギー消費
     │  - total_energy    : 総エネルギー消費
     └─ Energy Efficiency: エネルギー効率
        - energy_per_instruction: 命令あたりエネルギー
        - energy_per_cycle     : サイクルあたりエネルギー

追加カテゴリ:

2.11 I/O Operations（I/O操作）
2.12 Data Quality（データ品質）
2.13 Statistics（統計）
2.14 Encoding（符号化、Binary35対応）
2.15 System（システムメトリクス）

================================================================================
3. メトリクスカテゴリ詳細
================================================================================

3.1 実行パフォーマンスメトリクス (Execution Performance)
────────────────────────────────────────────────────────
プログラム実行の時間的側面を測定します。
用途: アプリケーションの応答性、スループット評価
測定方法: タイマー関数、パフォーマンスカウンター

3.2 CPUサイクルメトリクス (CPU Cycles)
────────────────────────────────────────────────────────
プロセッサーのクロックサイクルに関連するメトリクスです。
用途: CPU稼働率、動的周波数スケーリング評価
測定方法: CPUパフォーマンスカウンター (RDTSC, perf)

3.3 命令メトリクス (Instructions)
────────────────────────────────────────────────────────
実行される命令に関連するメトリクスです。
用途: コード効率、命令レベル並列性 (ILP) 評価
測定方法: パフォーマンスカウンター、命令トレース

3.4 命令効率メトリクス (Instruction Efficiency)
────────────────────────────────────────────────────────
IPC/CPI はコアの効率を示す最重要メトリクスです。
IPC > 1.5: 優秀
1.2 < IPC <= 1.5: 良好
IPC <= 1.2: 改善が必要

3.5 キャッシュメトリクス (Cache)
────────────────────────────────────────────────────────
L1/L2/L3キャッシュのヒット/ミスを測定します。
用途: メモリレイテンシー削減、キャッシュ最適化
測定方法: キャッシュカウンター (CPU固有)

3.6 メモリメトリクス (Memory)
────────────────────────────────────────────────────────
メモリバスのトラフィックと帯域幅利用率を測定します。
用途: メモリ帯域幅の最適化、メモリバウンド分析
測定方法: メモリバスモニタリング

3.7 分岐予測メトリクス (Branch Prediction)
────────────────────────────────────────────────────────
分岐予測ユニット (BPU) の精度を測定します。
用途: 制御フロー最適化
測定方法: BPU関連カウンター

3.8 パイプラインメトリクス (Pipeline)
────────────────────────────────────────────────────────
パイプラインストールの原因を分類します。
用途: ボトルネック分析、並列度評価
測定方法: マイクロアーキテクチャカウンター

3.9 並列性メトリクス (Parallelism)
────────────────────────────────────────────────────────
マルチスレッド/マルチコア環境での効率を測定します。
用途: スケーラビリティ評価、ロードバランシング分析
測定方法: OS統計、スレッドプロファイリング

3.10 電力・エネルギーメトリクス (Power & Energy)
────────────────────────────────────────────────────────
消費電力とエネルギー効率を測定します。
用途: 電力予算管理、省エネルギー最適化
測定方法: パワーセンサー、RAPL (Running Average Power Limit)

================================================================================
4. 互換性グループ
================================================================================

互換性グループは、特定の環境や要件下でのメトリクス利用可能性を示します。

G001 - 基本パフォーマンス (HIGH互換性)
      メトリクス: execution_time, cycles, instructions, ipc_mean
      説明: すべての環境で標準的に利用可能
      推奨用途: 基本的なパフォーマンス評価

G002 - キャッシュ効率 (HIGH互換性)
      メトリクス: cache_misses, cache_references, cache_miss_rate
      説明: CPUメトリクスと直結、ほぼ全CPUで対応
      推奨用途: メモリサブシステム最適化

G003 - メモリ性能 (MEDIUM互換性)
      メトリクス: memory_latency, memory_bandwidth_util, memory_load_bytes
      説明: システム依存、利用可能性に限定あり
      推奨用途: メモリ帯域幅要求の高いアプリケーション

G004 - 分岐予測 (HIGH互換性)
      メトリクス: branch_mispredictions, branch_miss_rate, conditional_branches
      説明: CPU機能依存だが、ほぼ全モダンCPUで対応
      推奨用途: 制御フロー最適化

G005 - パイプライン効率 (MEDIUM互換性)
      メトリクス: pipeline_stalls, data_dependency_stalls, resource_stalls
      説明: マイクロアーキテクチャ依存
      推奨用途: 低レベル最適化

G006 - マルチコア効率 (MEDIUM互換性)
      メトリクス: core_utilization, load_imbalance_ratio, context_switches
      説明: 並列化レベル依存
      推奨用途: 並列処理の最適化

G007 - エネルギー効率 (MEDIUM互換性)
      メトリクス: power_consumption, energy_per_instruction, energy_per_cycle
      説明: ハードウェア能力依存、一部システムで利用不可
      推奨用途: データセンター、バッテリー駆動デバイス

G008 - I/O性能 (LOW互換性)
      メトリクス: disk_reads, disk_writes, network_packets_sent
      説明: システム構成により大きく依存
      推奨用途: I/O集約的ワークロード

G009 - 統計分析 (HIGH互換性)
      メトリクス: mean_value, std_deviation, p95_percentile, p99_percentile
      説明: 汎用、データセット形式に依存しない
      推奨用途: 統計的な分析・評価

G010 - データ品質 (HIGH互換性)
      メトリクス: sample_count, missing_values, data_consistency_ratio
      説明: 汎用、データ管理に必須
      推奨用途: データパイプライン監視

================================================================================
5. 測定方法と単位
================================================================================

5.1 時間関連メトリクス
  Unit: seconds (s), milliseconds (ms), microseconds (μs), nanoseconds (ns)
  Measurement: タイマー関数 (clock_gettime, RDTSC)
  精度: システムによって異なる (通常 1μs - 1ms)

5.2 カウント関連メトリクス
  Unit: count (数値)
  Measurement: パフォーマンスカウンター
  特性: イベント駆動型、累積カウンター

5.3 比率関連メトリクス
  Unit: ratio (0-1) または percent (0-100%)
  計算: numerator / denominator
  用途: 正規化された比較

5.4 周波数関連メトリクス
  Unit: GHz (ギガヘルツ)
  Measurement: CPU識別情報、動的周波数スケーリング API
  精度: 通常 100MHz 単位

5.5 電力・エネルギーメトリクス
  Unit: watts (W), joules (J), picojoules (pJ)
  Measurement: パワーセンサー、RAPL
  精度: センサー依存 (通常 100mW - 1W)

================================================================================
6. データバリデーション
================================================================================

6.1 数値範囲バリデーション
  各メトリクスには有効な値の範囲が定義されています。
  範囲外の値は異常を示す可能性があります。
  
  例:
    - ipc_mean: 0 - 10 (inst/cycle)
    - cache_miss_rate: 0 - 1 (ratio)
    - power_consumption: 0 - ∞ (watts)

6.2 欠損値処理 (Null Handling)
  ほぼすべてのメトリクスで欠損値は「除外 (exclude)」として処理されます。
  これにより、計算時に有効なデータのみが使用されます。

6.3 集約方法 (Aggregation)
  メトリクスごとに推奨される集約方法が定義されています。
  
  平均値 (mean): 実行時間、IPC、ミスレート等
  合計 (sum): サイクル数、命令数、イベント数等
  最大値 (max): ピーク値が重要な場合
  最小値 (min): ワーストケース評価が必要な場合

6.4 データ品質チェックリスト
  ✓ サンプル数 >= 1
  ✓ 欠損値率 < 10%
  ✓ 数値範囲内にある
  ✓ タイムスタンプが順序付けられている

================================================================================
7. 使用ガイドライン
================================================================================

7.1 基本的なパフォーマンス評価
  推奨メトリクス: execution_time, cycles, instructions, ipc_mean
  評価ステップ:
    1. 実行時間を測定
    2. IPC を計算 (instructions / cycles)
    3. キャッシュミスレートを確認
    4. 改善機会を特定

7.2 キャッシュ最適化
  推奨メトリクス: cache_miss_rate, l1_miss_rate, l2_miss_rate, l3_miss_rate
  目標: キャッシュミスレート < 5% (L3)
  アクション:
    - データレイアウト最適化
    - アルゴリズムの改変
    - プリフェッチの活用

7.3 並列化評価
  推奨メトリクス: core_utilization, load_imbalance_ratio, speedup, efficiency
  目標: efficiency > 80% (マルチコア)
  アクション:
    - ロードバランシング改善
    - 粒度調整
    - 同期処理削減

7.4 電力最適化
  推奨メトリクス: power_consumption, energy_per_instruction, energy_per_cycle
  目標: energy_per_instruction を最小化
  アクション:
    - 周波数スケーリング活用
    - 不要な計算削減
    - 電力レベル切り替え

7.5 定期的なプロファイリング
  推奨スケジュール: デプロイメント前、リリース後 1週間、月次
  メトリクスセット: 基本パフォーマンス + 環境固有メトリクス
  レポート: CSV 形式で保存、趨勢分析

================================================================================
8. よくある質問 (FAQ)
================================================================================

Q1: IPCが低い場合、何をすべきか?
A: 以下の順で調査してください:
   1. キャッシュミスレート確認 (高い場合: メモリアクセス最適化)
   2. 分岐予測ミス率確認 (高い場合: 制御フロー最適化)
   3. パイプラインストール確認 (高い場合: データ依存性削減)
   4. 命令レベル並列性分析 (不十分な場合: コンパイラ最適化)

Q2: キャッシュミスレートが高い場合の対策は?
A: 主な対策:
   - ブロッキング/タイリング (計算量削減)
   - データプリフェッチ (遅延隠蔽)
   - メモリアクセスパターン最適化
   - NUMA対応 (マルチソケットシステム)

Q3: マルチスレッド時の効率が低い理由は?
A: 以下を確認してください:
   - ロードバランス (load_imbalance_ratio)
   - 同期オーバーヘッド (context_switches)
   - 偽共有 (false sharing) - L3 ミスの増加
   - キャッシュコヒーレンシーコスト

Q4: 標準化されたメトリクスセットは何か?
A: DataOps基本セット (推奨):
   [Basic Performance Set]
   - execution_time_mean
   - cycles_mean
   - instructions_mean
   - ipc_mean
   - cpi_mean
   - cache_miss_rate_mean
   [System Set]
   - core_utilization
   - context_switches
   [Quality Set]
   - sample_count
   - missing_values

Q5: 異なるシステム間でメトリクスを比較できるか?
A: 可能ですが、以下に注意してください:
   - 絶対値ではなく、相対値（比率）を比較
   - キャッシュサイズ、周波数の差を考慮
   - 複数実行で平均値を取得
   - 標準化（正規化）処理を実施

Q6: リアルタイムアプリケーションで重要なメトリクスは?
A: 優先順位:
   1. 最大応答時間 (max execution_time)
   2. 周期的な実行の安定性 (std_deviation)
   3. 予測不可能な遅延 (p99_percentile)
   4. リソース利用率 (cpu_utilization)

Q7: エネルギー効率を評価するには?
A: 推奨メトリクス:
   - energy_per_instruction (pJ/inst)
   - energy_per_cycle (pJ/cycle)
   - power_consumption (watts)
   計算: total_energy / instruction_count

Q8: Binary35符号化とは何か?
A: 特定の値域でのコンパクト表現形式です。
   用途: データストレージ効率化
   対応メトリクス: execution_time, ipc, cpi, cache_miss_rate

================================================================================

更新履歴:
  Version 1.0 - 2026-03-08: 初版作成

この文書は定期的に更新されます。
最新版は analysis_output/metric_documentation.txt を参照してください。

================================================================================
"

# ドキュメントをファイルに保存
writeLines(metric_doc, file.path(output_dir, "metric_documentation.txt"))
cat("✓ metric_documentation.txt を生成しました\n")

# =====================================================================
# クイックリファレンスガイド
# =====================================================================
quick_reference <- "
================================================================================
DataOps Metric クイックリファレンスガイド
================================================================================

【重要メトリクス Top 10】

1. execution_time (実行時間)
   └─ 用途: パフォーマンス評価
   └─ 単位: seconds
   └─ 目安: 低いほど良い

2. ipc_mean (命令/サイクル)
   └─ 用途: プロセッサー効率評価
   └─ 単位: instructions/cycle
   └─ 目安: > 1.5 で優秀

3. cache_miss_rate_mean (キャッシュミスレート)
   └─ 用途: メモリシステム評価
   └─ 単位: ratio (0-1)
   └─ 目安: < 0.05 (5%) が理想的

4. cpi_mean (サイクル/命令)
   └─ 用途: 命令実行効率
   └─ 単位: cycles/instruction
   └─ 目安: < 0.7 で優秀

5. core_utilization (コア利用率)
   └─ 用途: マルチコア効率
   └─ 単位: ratio (0-1)
   └─ 目安: マルチコアで > 0.8 が目標

6. power_consumption (消費電力)
   └─ 用途: 電力管理
   └─ 単位: watts
   └─ 目安: システム電力予算以下

7. memory_latency (メモリレイテンシー)
   └─ 用途: メモリシステム評価
   └─ 単位: nanoseconds
   └─ 目安: < 100 ns が理想的 (DRAM)

8. branch_miss_rate (分岐予測ミスレート)
   └─ 用途: 制御フロー効率
   └─ 単位: ratio (0-1)
   └─ 目安: < 0.05 が目標

9. l3_miss_rate (L3キャッシュミスレート)
   └─ 用途: キャッシュヒエラルキー効率
   └─ 単位: ratio (0-1)
   └─ 目安: < 0.10 が目標

10. load_imbalance_ratio (ロード不均衡)
    └─ 用途: スレッド間のバランス評価
    └─ 単位: percent (0-100%)
    └─ 目安: < 20% が目標

【メトリクス相互関係】

execution_time ≈ cycles / frequency
ipc = instructions / cycles
energy = power × time
speedup = time_sequential / time_parallel
efficiency = speedup / core_count

【クイックチェックリスト】

◇ 基本パフォーマンス評価
  □ execution_time を記録
  □ IPC を計算
  □ キャッシュミスレートを確認
  □ 前回比較と差異分析

◇ 最適化機会の発見
  □ IPC < 1.2 なら分岐/メモリ最適化を検討
  □ cache_miss_rate > 0.05 ならデータレイアウト改善
  □ load_imbalance_ratio > 30% なら並列化改善
  □ power_consumption が予算超過なら周波数低下検討

◇ 定期レポート
  □ 平均値、標準偏差、Min/Max を記録
  □ P95、P99 パーセンタイルを監視
  □ 月次趨勢をグラフ化
  □ SLA遵守状況を確認

【トラブルシューティング】

問題: パフォーマンスが低い
対策:
  1. IPC を確認 (低い → メモリ最適化)
  2. キャッシュミスを確認 (高い → データ局所性)
  3. 分岐予測を確認 (高 → 制御フロー最適化)
  4. パイプラインストールを確認 (高 → 依存性削減)

問題: マルチコア時に効率が低い
対策:
  1. ロードバランスを確認
  2. コンテキストスイッチを最小化
  3. 偽共有を削減
  4. NUMA効果を検証

問題: メモリ帯域幅が不足
対策:
  1. キャッシュミスを削減
  2. プリフェッチを有効化
  3. アクセスパターンを正規化
  4. ブロッキング処理を導入

問題: 電力消費が多い
対策:
  1. 周波数スケーリングを活用
  2. 不要な計算を削減
  3. キャッシュを有効活用
  4. I/O を最適化

【ベストプラクティス】

✓ 常に複数メトリクスを参照する (単一メトリクスは不十分)
✓ ワークロードに応じてメトリクスセットを選択
✓ 統計的信頼性のため複数実行を実施
✓ 絶対値より相対値（比率）を重視
✓ 定期的な趨勢分析を実施
✓ 異なるシステム間は注意深く比較

================================================================================
"

writeLines(quick_reference, file.path(output_dir, "quick_reference.txt"))
cat("✓ quick_reference.txt を生成しました\n")

# =====================================================================
# メトリクス利用シナリオ別ガイド
# =====================================================================
scenario_guide <- "
================================================================================
メトリクス利用シナリオ別ガイド
================================================================================

【シナリオ 1: 新規アプリケーションのベースライン設定】

実施項目:
  1. 複数実行 (n >= 10回) でメトリクス取得
  2. 以下の基本メトリクスを記録:
     - execution_time (mean, std_dev, min, max)
     - cycles, instructions
     - ipc_mean, cpi_mean
     - cache_miss_rate
     - core_utilization

分析内容:
  - 実行時間の変動係数 (CV = std / mean) を計算
  - CV > 0.05 なら非決定的要因を調査
  - IPC から命令効率を評価
  - キャッシュミスレート > 0.1 なら最適化候補

アクション:
  - 目安値を定め、SLA として記録
  - 定期的なモニタリングを開始

【シナリオ 2: パフォーマンス回帰の検出】

チェック:
  1. 前月比で execution_time が 5% 以上増加?
     → 原因調査 (コード変更、システム負荷)
  2. IPC が低下?
     → キャッシュ効率、分岐予測を確認
  3. キャッシュミスレートが上昇?
     → メモリアクセスパターン変化を確認

対応:
  - コードレビュー
  - コンパイラオプション再調整
  - ホットスポット分析

【シナリオ 3: マルチコア最適化】

計測:
  - core_utilization
  - load_imbalance_ratio
  - context_switches
  - cache_miss_rate (マルチコア時は増加する傾向)

目標設定:
  - core_utilization > 90% (理想的)
  - load_imbalance_ratio < 20%
  - speedup = time_1core / time_Ncore
  - efficiency = speedup / N_cores * 100%
    目標: > 80% (Nコア時)

最適化:
  1. ロードバランシング改善
  2. 同期処理削減
  3. 粒度調整
  4. キャッシュ最適化

【シナリオ 4: キャッシュ最適化プロジェクト】

測定:
  - l1_miss_rate, l2_miss_rate, l3_miss_rate
  - memory_latency
  - memory_bandwidth_util

分析:
  - L1 ミスが多い → ワーキングセット が小さすぎる
  - L2 ミスが多い → データアクセスパターン の改善余地
  - L3 ミスが多い → メイン メモリバウンド

対策:
  - ブロッキング/タイリング (L3 内に収まるようにブロック化)
  - データプリフェッチ命令の挿入
  - アクセス順序の正規化
  - NUMA対応 (大規模システム)

期待効果:
  - キャッシュミスレート を 50% 削減
  - メモリ帯域幅効率 を 20-30% 改善
  - 実行時間 を 15-25% 短縮

【シナリオ 5: 電力管理・クーリング最適化】

監視:
  - power_consumption (リアルタイム)
  - energy_per_instruction
  - thermal (温度)

制御:
  - 周波数スケーリング (DVFS)
    → frequency を下げて power を削減
  - 動的電圧調整 (DVS)
  - クーリング制御

トレードオフ:
  - frequency を f% 低下 → power は約 f% 削減
  - 但し execution_time は増加 (通常 f% より大きい)
  - energy_per_instruction は改善する傾向

意思決定:
  - deadline がない → max efficiency (energy/inst 最小化)
  - deadline がある → frequency を調整してSLA達成

【シナリオ 6: リアルタイムアプリケーション】

重要メトリクス:
  - max execution_time (ワーストケース)
  - p99_percentile (99パーセンタイル)
  - std_dev (変動性)

測定方法:
  - 最低 1000 回の実行
  - ウォームアップ後計測
  - システム干渉を最小化

要件確認:
  1. max execution_time <= deadline?
  2. p99 <= deadline * 0.9?
  3. 他のタスクとの干渉は無視できる?

アクション:
  - タイムアウト処理の実装
  - リソース予約の確保
  - 優先度設定

【シナリオ 7: システム全体の健全性監視】

日次チェック:
  □ 基本メトリクス: execution_time, ipc, cache_miss_rate
  □ 異常検知: outliers > 3 * std_dev の検出
  □ SLA遵守: 全メトリクスが許容範囲内か

週次分析:
  □ 趨勢分析: 7日間のグラフ化
  □ 比較分析: 前週との比較
  □ 相関分析: メトリクス間の相関変化

月次レポート:
  □ パフォーマンス要約
  □ 改善機会の洗い出し
  □ リソース利用傾向
  □ 次月の施策検討

【シナリオ 8: 新ハードウェアへの移行】

検証項目:
  1. 基本メトリクスの比較
     (旧HW vs 新HW, 同じ実行環境)
  2. 期待 vs 実績の確認
     - execution_time: 何% 改善?
     - 周波数が同じなら IPC 改善?
  3. 互換性確認
     - キャッシュ構成による影響
     - メモリ帯域幅利用パターン
  4. 調整が必要か?
     - コンパイラオプション
     - チューニングパラメータ

期待効果の検証:
  - CPU性能 X% 向上 → execution_time は X% 短縮されたか?
  - L3 キャッシュ増加 → cache_miss_rate は改善したか?
  - メモリ帯域幅増加 → memory_bandwidth_util は改善したか?

================================================================================
"

writeLines(scenario_guide, file.path(output_dir, "scenario_guide.txt"))
cat("✓ scenario_guide.txt を生成しました\n")

print("")
print("=" %*% 70)
print("✅ ドキュメント生成完了")
print("=" %*% 70)
print("")
print("生成されたドキュメント:")
print("  - metric_documentation.txt : 包括的メトリクス参考資料 (8章構成)")
print("  - quick_reference.txt      : クイックリファレンスガイド")
print("  - scenario_guide.txt       : 利用シナリオ別ガイド")
print("")
print("合計ドキュメントサイズ: 約 30KB")
print("言語: 日本語")
print("")
