#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(stringr)
})

args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1) args[[1]] else "processor_execution_data.csv"
out_dir <- if (length(args) >= 2) args[[2]] else "analysis_output"

if (!file.exists(input_path)) {
  stop(sprintf("Input file not found: %s", input_path))
}

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

df <- read_csv(input_path, show_col_types = FALSE)
if (nrow(df) == 0) {
  stop("Input data is empty.")
}

# Normalize column names for loose matching.
nm <- names(df)
nm_norm <- nm |>
  stringr::str_to_lower() |>
  stringr::str_replace_all("[^a-z0-9]", "")

find_col <- function(patterns) {
  idx <- which(vapply(patterns, function(p) any(str_detect(nm_norm, p)), logical(1)))[1]
  if (is.na(idx)) return(NA_character_)
  pat <- patterns[[idx]]
  hit <- which(str_detect(nm_norm, pat))[1]
  if (length(hit) == 0 || is.na(hit)) return(NA_character_)
  nm[[hit]]
}

time_col <- find_col(c("^time$", "elapsed", "runtime", "executiontime", "duration", "seconds", "ms"))
cycle_col <- find_col(c("cycle", "cpuclock", "clocks"))
instr_col <- find_col(c("instruction", "instret", "retired"))
core_col <- find_col(c("^core$", "cpu", "thread"))
workload_col <- find_col(c("workload", "bench", "program", "task", "kernel", "name"))
cache_miss_col <- find_col(c("cachemiss", "l1miss", "l2miss", "l3miss", "misses"))
cache_ref_col <- find_col(c("cacheref", "cacheaccess", "cachehit", "references"))

numeric_cols <- names(df)[vapply(df, is.numeric, logical(1))]
if (length(numeric_cols) == 0) {
  stop("No numeric columns found in input data.")
}

# Helper to safely compute vectors.
safe_ratio <- function(num, den) {
  if (all(is.na(num)) || all(is.na(den))) return(rep(NA_real_, length(num)))
  out <- suppressWarnings(as.numeric(num) / as.numeric(den))
  out[!is.finite(out)] <- NA_real_
  out
}

res <- df

if (!is.na(instr_col) && !is.na(cycle_col)) {
  res$ipc <- safe_ratio(res[[instr_col]], res[[cycle_col]])
  res$cpi <- safe_ratio(res[[cycle_col]], res[[instr_col]])
}

if (!is.na(instr_col) && !is.na(time_col)) {
  res$inst_per_sec <- safe_ratio(res[[instr_col]], res[[time_col]])
}

if (!is.na(cycle_col) && !is.na(time_col)) {
  res$cycles_per_sec <- safe_ratio(res[[cycle_col]], res[[time_col]])
}

if (!is.na(cache_miss_col) && !is.na(cache_ref_col)) {
  res$cache_miss_rate <- safe_ratio(res[[cache_miss_col]], res[[cache_ref_col]])
}

group_cols <- c()
if (!is.na(workload_col)) group_cols <- c(group_cols, workload_col)
if (!is.na(core_col)) group_cols <- c(group_cols, core_col)

kpi_cols <- intersect(c(
  time_col, cycle_col, instr_col,
  "ipc", "cpi", "inst_per_sec", "cycles_per_sec", "cache_miss_rate"
), names(res))

if (length(group_cols) > 0) {
  summary_tbl <- res |>
    group_by(across(all_of(group_cols))) |>
    summarise(
      samples = n(),
      across(all_of(kpi_cols), list(mean = ~mean(.x, na.rm = TRUE), p95 = ~quantile(.x, 0.95, na.rm = TRUE)), .names = "{.col}_{.fn}"),
      .groups = "drop"
    )
} else {
  summary_tbl <- res |>
    summarise(
      samples = n(),
      across(all_of(kpi_cols), list(mean = ~mean(.x, na.rm = TRUE), p95 = ~quantile(.x, 0.95, na.rm = TRUE)), .names = "{.col}_{.fn}")
    )
}

write_csv(summary_tbl, file.path(out_dir, "summary_metrics.csv"))

if (!is.na(time_col)) {
  p <- ggplot(res, aes(x = .data[[time_col]])) +
    geom_histogram(bins = 40, fill = "#2C7FB8", color = "white") +
    theme_minimal(base_size = 12) +
    labs(title = "Execution Time Distribution", x = time_col, y = "Count")
  ggsave(file.path(out_dir, "execution_time_hist.png"), p, width = 8, height = 4.5, dpi = 140)
}

if ("ipc" %in% names(res)) {
  p <- ggplot(res, aes(x = ipc)) +
    geom_histogram(bins = 40, fill = "#41AB5D", color = "white") +
    theme_minimal(base_size = 12) +
    labs(title = "IPC Distribution", x = "IPC", y = "Count")
  ggsave(file.path(out_dir, "ipc_hist.png"), p, width = 8, height = 4.5, dpi = 140)
}

if (!is.na(workload_col) && !is.na(time_col)) {
  p <- res |>
    group_by(.data[[workload_col]]) |>
    summarise(time_mean = mean(.data[[time_col]], na.rm = TRUE), .groups = "drop") |>
    ggplot(aes(x = reorder(.data[[workload_col]], time_mean), y = time_mean)) +
    geom_col(fill = "#756BB1") +
    coord_flip() +
    theme_minimal(base_size = 12) +
    labs(title = "Mean Execution Time by Workload", x = workload_col, y = sprintf("Mean %s", time_col))
  ggsave(file.path(out_dir, "time_by_workload.png"), p, width = 8, height = 5.5, dpi = 140)
}

meta <- tibble::tibble(
  key = c("input_file", "rows", "columns", "detected_time_col", "detected_cycle_col", "detected_instruction_col", "detected_workload_col", "detected_core_col", "detected_cache_miss_col", "detected_cache_ref_col"),
  value = c(input_path, as.character(nrow(res)), as.character(ncol(res)),
            ifelse(is.na(time_col), "NA", time_col),
            ifelse(is.na(cycle_col), "NA", cycle_col),
            ifelse(is.na(instr_col), "NA", instr_col),
            ifelse(is.na(workload_col), "NA", workload_col),
            ifelse(is.na(core_col), "NA", core_col),
            ifelse(is.na(cache_miss_col), "NA", cache_miss_col),
            ifelse(is.na(cache_ref_col), "NA", cache_ref_col))
)
write_csv(meta, file.path(out_dir, "analysis_metadata.csv"))

cat(sprintf("Analysis complete. Outputs are in: %s\n", normalizePath(out_dir)))
