# AGENTS.md - AI Assistant Context for example-project

> **What is this file?** AGENTS.md is an emerging open standard for providing
> AI coding assistants with project context. It is supported by Claude Code,
> Cursor, Windsurf, GitHub Copilot, and other AI tools. Think of it as a
> README for AI -- it tells any AI assistant how your project is structured,
> what conventions to follow, and what pitfalls to avoid. See the
> [README section on AGENTS.md](#about-agentsmd) for more details.

## Project Overview

This is a **teaching template** for Accounting/Finance empirical research
projects. It demonstrates downloading data from WRDS, transforming it,
producing publication-ready tables and figures, and outputting results to
LaTeX and MS Word.

The code is written in three languages: **R**, **SAS**, and **Stata**.
The R code is the most complete implementation. The SAS code handles data
download only. The Stata code handles analysis/tabulation only.

**This is a public teaching repository.** Code quality, readability, and
extensive comments matter more than efficiency. When making changes, preserve
the teaching style and add comments explaining *why*, not just *what*.

## Project Structure

```
example-project/
├── .env                    # Local environment config (gitignored)
├── AGENTS.md               # This file - AI assistant context
├── CLAUDE.md               # Claude Code specific config (imports this file)
├── README.md               # Main documentation and install guide
├── install-R.md            # R/RStudio/Git installation instructions
├── src/
│   ├── utils.R                       # Helper functions (winsorize, FF industries)
│   ├── 1-download-wrds-data.R        # Download from WRDS (R version)
│   ├── 1-download-wrds-data.sas      # Download from WRDS (SAS version)
│   ├── 2-transform-data.R            # Data cleaning and variable creation
│   ├── 3-figures.R                   # Publication-ready figures
│   ├── 4-analyze-data-and-tabulate-latex.R   # Tables for LaTeX output
│   ├── 4-analyze-data-and-tabulate-word.R    # Tables for Word output
│   ├── 4-analyze-data-Stata.do               # Tables in Stata (incl. .env setup guide)
│   └── MACROS.sas                            # SAS macro library
├── assets/                 # Screenshots and images for documentation
└── theme/                  # Optional RStudio theme and font
```

### Script Execution Order

Scripts are numbered and should be run in order:
1. `1-download-wrds-data.R` or `.sas` (requires WRDS credentials)
2. `2-transform-data.R`
3. `3-figures.R`
4. `4-analyze-data-*.R` or `.do`

Every R script loads `.env` via `dotenv` and sources `utils.R` at the top.
Packages are auto-installed via `pacman::p_load()` — no separate install step needed.
See `1-download-wrds-data.R` for detailed comments on `.env` setup and keyring
credential storage.

## Key Conventions

### Environment and Paths

- **All paths come from the `.env` file** via the `dotenv` R package or
  `projectpaths` + `doenv` in Stata. Never hardcode local paths in scripts.
- The `.env` file uses **forward slashes** even on Windows:
  `DATA_DIR=D:/Dropbox/example-project`
- R scripts load paths with: `library(dotenv); load_dot_env(".env");
  data_dir <- Sys.getenv("DATA_DIR")`
- Stata scripts load paths with: `project_paths_list, project(example-project) cd;
  doenv using ".env"; local data_dir "\`r(DATA_DIR)'"`
- The variable is called `data_dir` in R and `` `data_dir' `` in Stata.
  The old name `data_path` is deprecated.

### R Code Style

- **`pacman::p_load()` is used instead of `library()`** — it auto-installs
  missing packages, so users don't need a separate install step. Each script
  starts with `if (!require("pacman")) install.packages("pacman")` followed
  by `pacman::p_load(...)`.
- `tidyverse` is always loaded last to avoid package conflicts
- The native pipe `|>` is preferred over `%>%` (though some older code
  may still use `%>%`)
- `glue("{data_dir}/filename")` is used for dynamic file paths
- Variable labels use LaTeX math notation (e.g., `$ROA_{t+1}$`)
- The `formattable` package handles number formatting in tables
- `modelsummary` is used for regression tables; `kableExtra` for LaTeX;
  `flextable` + `officer` for Word output

### Stata Code Style

- `reghdfe` is used for fixed effects regressions (comparable to R's `fixest`)
- `estout`/`esttab` is used for table output
- `estfe` adds fixed effects indicator rows
- Triple-slash `///` for line continuation
- Global macros for control variable lists: `global controls rd at mve`

### SAS Code Style

- SAS is used only for the WRDS data download step as an alternative to R
- `%include` loads macro files
- Standard Compustat filters: `indfmt='INDL' and datafmt='STD'
  and popsrc='D' and consol='C'`

### Data and Variables

- **WRDS** (Wharton Research Data Services) is the data source
- `gvkey` = firm identifier, `datadate` = fiscal year end date
- `calyear` = calendar year (aligned to June, assuming 3-month reporting lag)
- `roa` = return on assets (earnings / total assets)
- `roa_lead_1` = next year's ROA (note: the `_1` suffix matters)
- `loss` = binary indicator (1 if earnings < 0)
- `FF12` / `FF49` = Fama-French industry classifications
- Winsorization at 1%/99% is the default (see `winsorize_x` in utils.R)
- Financial firms (SIC 60-69) and utilities (SIC 49) are excluded

### Output

- LaTeX output goes to `{data_dir}/output/*.tex`
- Word output goes to `{data_dir}/output/*.docx` or `*.rtf`
- Figures go to `{data_dir}/output/*.pdf` (LaTeX) or `*.png` (Word)
- The LaTeX template on Overleaf reads the `.tex` files directly

## Common Pitfalls

- **dbplyr vs dplyr**: In `1-download-wrds-data.R`, code before `collect()`
  runs on the WRDS PostgreSQL server. Use `is.na()` not `is.null()` for
  NULL checks in dbplyr contexts. Some R functions need `sql()` wrappers.
- **SAS comparison operators**: Use `>=` not `=>` (SAS-specific syntax).
- **Stata variable names**: Use `roa_lead_1` (with `_1`), not `roa_lead`.
- **FF49 industry codes**: The upper bound for "Restaurants, Hotels, Motels"
  is SIC 7996, and for "Almost Nothing" is SIC 3999. Check `utils.R` for
  the exact numeric mappings.
- **Forward slashes in .env**: Always use `/` not `\` in paths, even on
  Windows. R and Stata both handle forward slashes correctly.
