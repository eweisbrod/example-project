---
title: JAR Data Policy
nav_order: 3
---

# JAR Data and Code Sharing Policy

This template is designed to satisfy the *Journal of Accounting Research*'s Data and Code Sharing Policy (<https://onlinelibrary.wiley.com/page/journal/1475679x/homepage/forauthors.html#DataPolicy>). The policy expects authors to provide three things:

1. **Code** that converts raw data into the final analytical dataset and produces the reported tables and figures.
2. **A comprehensive log file** documenting the end-to-end execution of that code.
3. **Identifiers** (e.g., `gvkey`, `permno`) of the observations comprising the final sample.

`project-template` is designed around these requirements:

- The pipeline splits raw WRDS pulls (`RAW_DATA_DIR`) from derived data (`DATA_DIR`). A replication run can re-execute scripts 2-4 against the original researcher's preserved raw inputs without hitting WRDS.
- Every pipeline step produces a **per-script log in the SAS-log style** — every command echoed, output interleaved, plain text. R steps go through `batch_run()` (an `R CMD BATCH` wrapper in `utils.R`); Python steps go through an equivalent `batch_run()` in `utils.py` that subprocesses through an AST-based echo wrapper; Stata's native `log using` and SAS's native `proc printto` produce the same shape. All four supported languages emit visually consistent logs.
- The `5-data-provenance.{R,py}` step exports `sample-identifiers.{parquet,csv}` (gvkey, permno, rdq, datadate, fyearq, fqtr) and prints SHA256 hashes for every raw, derived, and output file. That step's own `.Rout` / `.log` is the project's content-addressed provenance record.
