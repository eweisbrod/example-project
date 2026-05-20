---
title: 'example-project: A polyglot teaching template for reproducible empirical accounting and finance research'
tags:
  - accounting
  - finance
  - reproducibility
  - empirical research
  - WRDS
  - R
  - Python
  - Stata
  - LaTeX
  - data and code sharing policy
authors:
  - name: Eric H. Weisbrod
    orcid: 0000-0000-0000-0000
    affiliation: 1
affiliations:
  - name: University of Kansas, USA
    index: 1
date: 30 April 2026
bibliography: paper.bib
---

# Summary

`example-project` is a teaching hub for empirical accounting and
finance research. It pairs a JOSE paper (this document) and an
introductory README with two companion template repositories that,
together, walk a student or new researcher from raw data on a
database server through to a publication-ready PDF:

- [**`project-template`**](https://github.com/eweisbrod/project-template) — a research-pipeline template
  shipping parallel **R** and **Python** implementations of every
  numbered step (download, transform, figures, analyze/tables, data
  provenance), plus a **Stata** implementation of the analyze/tables
  step that reads the `.dta` written by either R or Python's
  transform. At first run, the template asks the user to pick a
  language combination (Full R, Full Python, Python + R, Python +
  Stata, R + Stata, or all three) and prunes the irrelevant files;
  the result is a clean single- or multi-language project skeleton
  tailored to the user's stack.
- [**`overleaf-template`**](https://github.com/eweisbrod/overleaf-template) — a LaTeX paper template
  pre-wired to the table and figure files produced by
  `project-template`. It also serves as a tutorial in academic LaTeX
  use, demonstrating biblatex-chicago citations (in-text,
  parenthetical, possessive, prefixed, and `et al.` forms),
  cross-referenceable hypothesis and research-question environments,
  and a section structure suitable for accounting and finance
  journals.

The example analysis throughout the templates is a quarterly
earnings-announcement event study using WRDS data
[@bochkay2022roles]: unexpected earnings (UE) interacted
with a same-sign indicator on the seasonal change in sales, regressed
on three-day buy-and-hold abnormal returns. The same analysis is
implemented in R, Python, and Stata in parallel for the analyze/tables
step, against the same data, demonstrating cross-language consistency
in the published tables.

# Statement of Need

Empirical accounting and finance research has a high coding floor.
PhD students and junior faculty are expected to produce reproducible
analyses across a stack of database access (typically WRDS), data
manipulation, regression, and table/figure formatting tools — but
formal training in this end-to-end workflow is uncommon. Most
researchers learn by inheriting their advisor's scripts or piecing
together tutorials. The result is often a tangle of ad-hoc files
that runs once on the original analyst's machine and is difficult for
collaborators (or referees) to reproduce.

This gap matters especially now because top accounting and finance
journals are formalizing data and code sharing policies modeled on
norms long established in economics. The Journal of Accounting
Research's Data and Code Sharing Policy [@JARpolicy], for example,
asks authors to provide three artifacts at submission: (1) the code
that converts raw data into the final analytical dataset and produces
the reported tables and figures, (2) a comprehensive log file
documenting the end-to-end execution of that code, and (3) the
identifiers (e.g., `gvkey`, `permno`) of the observations comprising
the final sample. Other accounting and finance journals (Journal of
Financial Economics; Review of Financial Studies; Management Science;
Accounting, Organizations and Society) have adopted comparable
requirements. A new researcher writing their first replicable
JAR-quality submission has to learn not just how to download CRSP
returns and run a regression, but how to package the work as a
reproducible artifact.

`example-project` is designed around three observations that follow
from this landscape:

1. **Researchers don't write in only one language.** A typical
   accounting or finance project involves at least two of R, Python,
   and Stata, often inherited from coauthors or mandated by
   collaborators. Existing teaching resources (e.g., @french2023r;
   @donoghue2022course) tend to be single-language. The polyglot
   template ships parallel R/Python/Stata implementations and lets
   the user pick a working subset rather than committing to one
   language. It also demonstrates cross-language consistency: a
   regression run in `pyfixest` and `fixest` and `reghdfe` produces
   the same numbers, and the template documents how to verify that.

2. **The journal-policy artifacts should be produced by the
   pipeline, not added at submission time.** `project-template`
   structures every pipeline run to emit a per-script log
   (SAS-log–shaped, plain text, command + output interleaved across
   all four supported languages — R produces `.Rout` files via
   `R CMD BATCH`; Python produces `.log` files via an AST-walking
   wrapper; Stata and SAS use their native `log using` /
   `proc printto`). A final `5-data-provenance` step exports
   sample-identifier files in both Parquet and CSV and prints an
   inventory of every raw, derived, and output file with mtime,
   size, and SHA256 hash. The resulting artifact set is what JAR
   asks for, produced as a side effect of running the pipeline.

3. **The "last mile" of formatting tables for a journal manuscript
   is undertaught.** Most students can run a regression; far fewer
   know how to produce a publication-grade `\begin{tabular}` block
   with fixed-effect indicator rows, clustered standard errors,
   significance stars, and consistent number formatting that matches
   the conventions of accounting and finance journals.
   `project-template` produces these tables in three frameworks
   (`modelsummary`+`kableExtra` in R, `pyfixest`+`great_tables` in
   Python, `reghdfe`+`estout` in Stata), and `overleaf-template`
   shows how to drop the resulting `.tex` files into a
   citation-ready manuscript.

The intended audience is researchers building their first end-to-end
empirical project: PhD students, junior faculty, and collaborators
who need a starting skeleton rather than a finished course. The
templates are GitHub template repositories and are designed to be
used via the "Use this template" workflow: clone, customize,
publish.

# Story of the Software

The pipeline is organized as five numbered scripts that run in
order. Each step has parallel implementations in the languages the
user picked at setup time:

1. `1-download-data` — connects to WRDS via the PostgreSQL endpoint,
   pulls Compustat fundq, the CCM link table, CRSP stocknames, the
   CRSP daily stock file, and the CRSP value-weighted index. Large
   tables are streamed to parquet via a server-side cursor so peak
   RAM stays bounded; small tables use the obvious read-and-write
   pattern. A `skip_if_exists` default keeps the raw inputs immutable
   on re-runs.

2. `2-transform-data` — merges fundq with the CCM link and SIC
   codes, constructs UE and the same-sign indicator, applies sample
   filters, and joins event-window CRSP returns to compute
   buy-and-hold abnormal returns (BHAR). DuckDB is used to query
   the parquet files directly without loading the largest table
   (CRSP daily, ~100M rows) into memory.

3. `3-figures` — produces five publication-ready figures
   (industry-level same-sign frequency; size-quintile time series;
   correlation heatmap; event-study CAR plot; year-by-year ERC with
   confidence bands) using `ggplot2` in R and `plotnine` in Python.

4. `4-analyze-data` — produces a sample-selection table, a
   frequency table by decade, descriptive statistics, a correlation
   matrix, and the main regression table with cumulative fixed
   effects. Outputs land in `output/` as `.tex` files for LaTeX,
   `.docx` for Word (R), and `.rtf` for Word (Stata). A
   `-r` / `-py` / `-stata` filename suffix lets the same analysis be
   produced and inspected side-by-side across languages.

5. `5-data-provenance` — exports the sample-identifier file (gvkey,
   permno, rdq, datadate, fyearq, fqtr) in both parquet and CSV and
   prints an inventory of `RAW_DATA_DIR`, `DATA_DIR`, and
   `OUTPUT_DIR` with mtime, size, and SHA256 hash. Together with
   the per-script logs, this satisfies the JAR policy artifact set.

A `run-all.{R,py}` master script chains the steps via a small
`batch_run()` helper that spawns each script in a fresh child
process and writes a `log/<script>.{Rout,log}` file in the
SAS-log–shaped format that journal reviewers familiar with SAS or
Stata logs recognize at a glance. When the user picked a
Stata-inclusive combo at setup, the .do file is still on disk and
`run-all` calls it via `batch_run_stata()`; otherwise that step is
skipped automatically.

The setup itself is a `project_setup()` function in `utils.{R,py}`,
called at the top of `1-download-data.{R,py}`. On a fresh clone (no
`.env` file yet) it walks the user through choosing a language
combination, entering data and output directories, storing WRDS
credentials in the OS keyring (Windows Credential Manager / macOS
Keychain), and optionally pruning the files for the languages they
didn't pick. On every subsequent run it sees `.env` on disk and
returns immediately. Setup is therefore not a separate step the
user has to remember to run; it happens the first time they execute
the pipeline.

# Acknowledgements

This template builds on code originally developed for
@bochkay2022roles and @weisbrod2019stockholders. The author thanks
PhD students and colleagues who have used and given feedback on
earlier versions of these materials.

# References
