#!/usr/bin/env Rscript
# Verify R dependencies
packages <- c("dplyr", "tidyr", "readr", "stringr", "ggplot2", "tibble", "purrr")
missing <- packages[!sapply(packages, function(p) require(p, character.only = TRUE, quietly = TRUE))]

if (length(missing) > 0) {
  cat("Missing packages:\n")
  for (pkg in missing) cat(sprintf("  - %s\n", pkg))
  cat("\nInstalling missing packages...\n")
  install.packages(missing, quiet = TRUE)
} else {
  cat("All required packages are installed!\n")
}

# Verify data files
files_to_check <- c(
  "processor_execution_data.csv",
  "analysis_output/summary_metrics.csv",
  "analysis_output/summary_metrics_binary35.csv"
)

cat("\nData files status:\n")
for (file in files_to_check) {
  if (file.exists(file)) {
    cat(sprintf("  ✓ %s\n", file))
  } else {
    cat(sprintf("  ✗ %s (NOT FOUND)\n", file))
  }
}

cat("\nSetup verification complete!\n")
