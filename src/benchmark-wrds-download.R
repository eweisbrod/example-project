# Benchmark WRDS Download Methods
# ================================
# Compares three approaches for downloading WRDS data to parquet:
#
#   Method 1: dbplyr collect()     — simple, loads entire result into RAM
#   Method 2: Chunked dbFetch()    — RAM-safe, streams batches to parquet
#   Method 3: DuckDB postgres      — fast, but requires DuckDB postgres extension
#
# Each method downloads the same table (comp.company, ~35k rows) and reports
# wall-clock time and peak memory usage. Adjust TEST_TABLE below to test with
# larger tables if desired.
#
# Requirements:
#   .env with DATA_DIR
#   WRDS credentials stored via keyring::key_set("wrds_user") / key_set("wrds_pw")
#   R packages: dotenv, keyring, DBI, RPostgres, dbplyr, arrow, duckdb, tidyverse
#
# Usage:
#   Source this script in RStudio, or run from the command line:
#     Rscript src/benchmark-wrds-download.R

library(dotenv)
library(DBI)
library(RPostgres)
library(dbplyr)
library(arrow)
library(duckdb)
library(glue)
library(tidyverse)

load_dot_env(".env")
data_dir <- Sys.getenv("DATA_DIR")
wrds_user <- keyring::key_get("wrds_user")

# ── Configuration ────────────────────────────────────────────────────────────

# Which table to benchmark. comp.company is small enough to be fast but large
# enough to show differences. For a real stress test, try comp.funda (with
# filters) or crsp.dsf_v2 (with a WHERE clause).
TEST_SCHEMA <- "comp"
TEST_TABLE  <- "company"

# Optional WHERE clause (without the WHERE keyword). Set to NULL for full table.
# Example: "datadate >= '2020-01-01'"
TEST_WHERE <- NULL

# Batch size for chunked download (Method 2)
BATCH_SIZE <- 50000

# Output directory for benchmark parquet files (cleaned up at the end)
bench_dir <- file.path(data_dir, "benchmark_temp")
dir.create(bench_dir, showWarnings = FALSE, recursive = TRUE)


# ── Helper: get peak memory ──────────────────────────────────────────────────

# Simple memory tracking using gc() — reports max memory used in MB
# Call reset_mem() before a method, get_peak_mem() after
reset_mem <- function() {
  gc(reset = TRUE)
  invisible(NULL)
}

get_peak_mem <- function() {
  mem <- gc()
  # gc() returns matrix; columns 1-2 are Ncells/Vcells, rows are used/max
  # Column 6 ("max used" Mb) is what we want — sum of Ncells + Vcells max
  peak_mb <- sum(mem[, 6])
  peak_mb
}


# ── WRDS Connection ──────────────────────────────────────────────────────────

cat("Connecting to WRDS...\n")

wrds <- dbConnect(
  Postgres(),
  host     = "wrds-pgdata.wharton.upenn.edu",
  port     = 9737,
  user     = wrds_user,
  password = keyring::key_get("wrds_pw"),
  sslmode  = "require",
  dbname   = "wrds"
)

cat(glue("Connected. Benchmarking {TEST_SCHEMA}.{TEST_TABLE}"), "\n")
if (!is.null(TEST_WHERE)) cat(glue("  WHERE {TEST_WHERE}"), "\n")
cat("\n")


# ── Method 1: dbplyr + collect() ─────────────────────────────────────────────
# This is the standard approach from 1-download-wrds-data.R.
# Simple and readable, but loads the entire result set into R's memory before
# writing to disk. Fine for small-to-medium tables, but can blow up RAM on
# large tables like crsp.dsf (tens of GB).

cat("=" |> strrep(60), "\n")
cat("Method 1: dbplyr + collect()\n")
cat("=" |> strrep(60), "\n")

out1 <- file.path(bench_dir, "method1.parquet")
reset_mem()

t1 <- system.time({
  tbl_ref <- tbl(wrds, in_schema(TEST_SCHEMA, TEST_TABLE))

  if (!is.null(TEST_WHERE)) {
    # Build the WHERE clause using dplyr::filter + sql()
    tbl_ref <- tbl_ref |> filter(sql(TEST_WHERE))
  }

  df <- tbl_ref |> collect()
  arrow::write_parquet(df, out1, compression = "zstd")
  rm(df)
})

mem1 <- get_peak_mem()
size1 <- file.size(out1) / 1e6
rows1 <- nrow(arrow::read_parquet(out1))

cat(glue("  Time:    {round(t1['elapsed'], 1)}s"), "\n")
cat(glue("  Rows:    {format(rows1, big.mark=',')}"), "\n")
cat(glue("  File:    {round(size1, 1)} MB"), "\n")
cat(glue("  Peak RAM: ~{round(mem1, 0)} MB (R process)"), "\n\n")


# ── Method 2: Chunked dbSendQuery + dbFetch ──────────────────────────────────
# RAM-safe approach. Uses a server-side cursor to stream rows in batches,
# writing each batch directly to parquet. Peak memory usage is proportional
# to batch_size, not to the full table. No new dependencies beyond what
# 1-download-wrds-data.R already uses (DBI, RPostgres, arrow).
#
# The trade-off: produces multiple parquet files (one per batch) that you
# read back with arrow::open_dataset(). Slightly more code than collect().

cat("=" |> strrep(60), "\n")
cat("Method 2: Chunked dbFetch + write_parquet (RAM-safe)\n")
cat("=" |> strrep(60), "\n")

out2_dir <- file.path(bench_dir, "method2_chunks")
dir.create(out2_dir, showWarnings = FALSE)
reset_mem()

t2 <- system.time({
  sql_query <- glue("SELECT * FROM {TEST_SCHEMA}.{TEST_TABLE}")
  if (!is.null(TEST_WHERE)) {
    sql_query <- glue("{sql_query} WHERE {TEST_WHERE}")
  }

  res <- dbSendQuery(wrds, sql_query)
  batch_num <- 0
  total_rows <- 0

  while (!dbHasCompleted(res)) {
    chunk <- dbFetch(res, n = BATCH_SIZE)
    if (nrow(chunk) == 0) break

    batch_num <- batch_num + 1
    total_rows <- total_rows + nrow(chunk)

    arrow::write_parquet(
      chunk,
      file.path(out2_dir, sprintf("batch_%03d.parquet", batch_num)),
      compression = "zstd"
    )
  }

  dbClearResult(res)
})

mem2 <- get_peak_mem()

# Calculate total size of all chunk files
chunk_files <- list.files(out2_dir, full.names = TRUE)
size2 <- sum(file.size(chunk_files)) / 1e6

cat(glue("  Time:    {round(t2['elapsed'], 1)}s"), "\n")
cat(glue("  Rows:    {format(total_rows, big.mark=',')}"), "\n")
cat(glue("  File:    {round(size2, 1)} MB ({batch_num} chunks)"), "\n")
cat(glue("  Peak RAM: ~{round(mem2, 0)} MB (R process)"), "\n")
cat("  Read back with: arrow::open_dataset('path/to/chunks/')\n\n")


# ── Method 3: DuckDB postgres extension ──────────────────────────────────────
# Uses DuckDB's postgres extension to ATTACH the WRDS server and COPY directly
# to parquet. This is typically the fastest approach because DuckDB handles the
# data transfer and parquet writing in optimized C++, bypassing R's memory.
#
# Caveat: Requires DuckDB to download its postgres extension on first use.
# This can fail behind university firewalls or restrictive proxy servers.
# If it fails for you, Method 2 is a reliable fallback.

cat("=" |> strrep(60), "\n")
cat("Method 3: DuckDB ATTACH + COPY TO parquet\n")
cat("=" |> strrep(60), "\n")

out3 <- file.path(bench_dir, "method3.parquet")
reset_mem()

wrds_pw <- keyring::key_get("wrds_pw")

t3 <- tryCatch({
  system.time({
    con <- duckdb::dbConnect(duckdb::duckdb())

    # Load the postgres extension — this is where firewall issues can occur
    dbExecute(con, "INSTALL postgres; LOAD postgres;")

    uri <- glue("postgres://{wrds_user}:{wrds_pw}@wrds-pgdata.wharton.upenn.edu:9737/wrds")
    dbExecute(con, glue("ATTACH '{uri}' AS wrds (TYPE POSTGRES, READ_ONLY)"))

    select_sql <- glue("SELECT * FROM wrds.{TEST_SCHEMA}.{TEST_TABLE}")
    if (!is.null(TEST_WHERE)) {
      select_sql <- glue("{select_sql} WHERE {TEST_WHERE}")
    }

    copy_sql <- glue("COPY ({select_sql}) TO '{out3}' (FORMAT PARQUET, COMPRESSION ZSTD)")
    dbExecute(con, copy_sql)

    duckdb::dbDisconnect(con, shutdown = TRUE)
  })
}, error = function(e) {
  cat("  ERROR: ", conditionMessage(e), "\n")
  cat("  (This often happens if DuckDB can't download its postgres extension.\n")
  cat("   Check your firewall/proxy settings.)\n\n")
  NULL
})

# Clear the password from memory
rm(wrds_pw)

if (!is.null(t3)) {
  mem3 <- get_peak_mem()
  size3 <- file.size(out3) / 1e6
  rows3 <- nrow(arrow::read_parquet(out3))

  cat(glue("  Time:    {round(t3['elapsed'], 1)}s"), "\n")
  cat(glue("  Rows:    {format(rows3, big.mark=',')}"), "\n")
  cat(glue("  File:    {round(size3, 1)} MB"), "\n")
  cat(glue("  Peak RAM: ~{round(mem3, 0)} MB (R process)"), "\n\n")
}


# ── Summary ──────────────────────────────────────────────────────────────────

cat("\n")
cat("=" |> strrep(60), "\n")
cat("SUMMARY\n")
cat("=" |> strrep(60), "\n")
cat(glue("Table: {TEST_SCHEMA}.{TEST_TABLE}"), "\n")
if (!is.null(TEST_WHERE)) cat(glue("WHERE: {TEST_WHERE}"), "\n")
cat("-" |> strrep(60), "\n")
cat(sprintf("%-35s %8s %10s\n", "Method", "Time(s)", "Peak RAM"))
cat("-" |> strrep(60), "\n")
cat(sprintf("%-35s %8.1f %8.0f MB\n", "1. dbplyr + collect()", t1['elapsed'], mem1))
cat(sprintf("%-35s %8.1f %8.0f MB\n", "2. Chunked dbFetch (RAM-safe)", t2['elapsed'], mem2))
if (!is.null(t3)) {
  cat(sprintf("%-35s %8.1f %8.0f MB\n", "3. DuckDB ATTACH + COPY", t3['elapsed'], mem3))
}
cat("-" |> strrep(60), "\n\n")

cat("Notes:\n")
cat("  - Method 1 is simplest but loads everything into RAM\n")
cat("  - Method 2 caps RAM at ~batch_size rows; reliable everywhere\n")
cat("  - Method 3 is fastest but needs DuckDB postgres extension\n")
cat("  - For small tables (<1M rows), differences are marginal\n")
cat("  - Re-run with a bigger table (e.g., crsp.dsf_v2) to see real differences\n\n")


# ── Cleanup ──────────────────────────────────────────────────────────────────

dbDisconnect(wrds)
unlink(bench_dir, recursive = TRUE)
cat("Temp files cleaned up. Done.\n")
