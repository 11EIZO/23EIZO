#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
})

args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1) args[[1]] else "analysis_output/summary_metrics.csv"
out_path <- if (length(args) >= 2) args[[2]] else "analysis_output/summary_metrics_binary35.csv"
scale_factor <- if (length(args) >= 3) as.numeric(args[[3]]) else 1000000

if (!file.exists(input_path)) {
  stop(sprintf("Input file not found: %s", input_path))
}

# 0 -> 3, 1 -> 5 のカスタム2進表現（対象はscale後に32bit整数へ収まる値）
int_to_binary35 <- function(x) {
  if (is.na(x)) return(NA_character_)
  n <- as.integer(round(abs(x)))
  if (n == 0L) return("3")
  bits <- as.character(intToBits(n))
  bit_str <- paste0(rev(bits), collapse = "")
  bit_str <- sub("^0+", "", bit_str)
  chartr("01", "35", bit_str)
}

raw <- read_csv(input_path, show_col_types = FALSE)
metric_cols <- intersect(
  c("execution_time_mean", "ipc_mean", "cpi_mean", "cache_miss_rate_mean"),
  names(raw)
)

if (length(metric_cols) == 0) {
  stop("No supported metric columns found for binary35 conversion.")
}

encoded <- raw
for (col in metric_cols) {
  squared_col <- paste0(col, "_sq")
  integer_col <- paste0(col, "_sq_int")
  binary35_col <- paste0(col, "_bin35")

  encoded[[squared_col]] <- raw[[col]] ^ 2
  encoded[[integer_col]] <- round(encoded[[squared_col]] * scale_factor)
  encoded[[binary35_col]] <- vapply(encoded[[integer_col]], int_to_binary35, character(1))
}

write_csv(encoded, out_path)
cat(sprintf("Wrote %s\n", normalizePath(out_path)))
