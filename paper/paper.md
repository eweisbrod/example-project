---
title: '`example-project`: A Reproducible Empirical Research Template'
tags:
  - accounting
  - finance
  - empirical research
  - reproducible research
  - data science
  - R
  - Python
  - Stata
  - SAS
  - LaTeX
  - WRDS
  - data and code sharing policy
authors:
  - name: Eric H. Weisbrod
    orcid: 0000-0002-8814-250X
    affiliation: 1
affiliations:
  - name: School of Business, University of Kansas, USA
    index: 1
date: 24 May 2026
bibliography: paper.bib
---

# Summary

`example-project` is an open-source teaching hub and template suite for reproducible empirical research, primarily targeting empirical business researchers in accounting and finance. The materials are organized as three Git repositories that together cover the workflow from raw database access through publication-grade manuscript production:

- [**`example-project`**](https://github.com/eweisbrod/example-project) — the teaching hub. Contains in-depth chapters on project structure, version control with Git and GitHub, integrated development environment (IDE) setup, Python virtual environments, environment variables and configuration files, AI-assistant integration via `AGENTS.md`, and a **SAS** [@SAS] macro reference for projects that retain SAS code.
- [**`project-template`**](https://github.com/eweisbrod/project-template) — a GitHub template repository implementing a five-step empirical pipeline (data download, transformation, figures, analysis tables, and provenance reporting) with parallel implementations in **R** [@RCoreTeam] and **Python**, plus a **Stata** [@Stata] implementation of the analysis-and-tables step. At first run, the template prompts the user to select a language combination and prunes the unused files.
- [**`overleaf-template`**](https://github.com/eweisbrod/overleaf-template) — a LaTeX manuscript template designed to consume the table and figure outputs of `project-template`, configured for use with [Overleaf](https://www.overleaf.com/) for real-time multi-author editing, and demonstrating `biblatex-chicago` citations, hypothesis-numbering conventions, and a section structure suitable for journals.

The running example throughout the materials is a quarterly earnings-announcement event study using data from [Wharton Research Data Services (WRDS)](https://wrds-www.wharton.upenn.edu/). Unexpected earnings, interacted with a same-sign indicator on the seasonal change in sales, are regressed on three-day buy-and-hold abnormal returns. The same regression is implemented in R, Python, and Stata in parallel to demonstrate cross-language consistency in the published tables. All materials are released under the Creative Commons Attribution 4.0 International (CC-BY-4.0) license, and the templates use GitHub's "Use this template" workflow so that instructors and individual researchers can spin up customized copies without forking.

# Statement of Need

Empirical business research depends on an interconnected stack of database access (typically WRDS), data manipulation, statistical modeling, and publication-grade table and figure formatting. Formal training in this end-to-end workflow is uncommon in business school doctoral programs, and most researchers in the field arrive with no training in computer science or software development. 

At the same time, academic journals in business fields are beginning to formalize data and code sharing policies modeled on established norms in economics. For example, the 2024 update to the *Journal of Accounting Research's* Data and Code Sharing Policy [@JARpolicy] requires submitting authors to provide three artifacts: (1) the code that produces the analytical dataset and the reported tables and figures from raw inputs, (2) a comprehensive log file documenting end-to-end execution, and (3) identifiers of the observations comprising the final sample. Comparable requirements have been adopted at several other major journals in the field. Prospective authors must therefore learn not only the substantive skills for conducting empirical research but the workflow skills required to document and package the research pipeline in compliance with modern journal policies.

Existing pedagogical resources address parts of this gap. For example, @french2023r and @donoghue2022course cover R programming with applications to financial data. These resources tend to be single-language, focus on the estimation step rather than the surrounding workflow, and do not directly address the journal-policy artifacts. The materials presented here are designed to fill the remaining gap, with three distinguishing features:

1. **Polyglot by design.** Empirical business research projects often involve combinations of R, Python, SAS and Stata code. For example, some researchers use one language to collect and manipulate data, while using a second language to analyze the data and prepare tables. The `project-template` ships parallel implementations in three languages and allows the user to select any subset at setup. Cross-language consistency is verified by producing the same regression tables via `pyfixest` [@pyfixest] in Python, `fixest` [@fixest] with `modelsummary` [@modelsummary] in R, and `reghdfe` [@reghdfe] with `estout` [@estout] in Stata.

2. **Journal-policy artifacts produced as a by-product of running the pipeline.** Every pipeline step emits a per-script log file in a uniform plain-text format across all supported languages, and a final provenance step exports sample-identifier files and a content-addressed (SHA256) inventory of every raw, derived, and output file. The resulting artifact set matches what major accounting and finance journals require at submission.

3. **Publication-grade table formatting.** Most graduate programs cover statistical estimation but undertrain the "last mile" of producing journal-quality tables with fixed-effect indicator rows, clustered standard errors, significance markers, and consistent number formatting. The templates produce these tables in all three languages and demonstrate how to integrate the resulting `.tex` files into a LaTeX manuscript via the companion `overleaf-template`.


# Target Audience and Learning Objectives

The primary audience is PhD students and early-career researchers building their first reproducible empirical project. A secondary audience is experienced researchers seeking a tested project skeleton with reproducibility conventions already in place. No prior software-engineering training is assumed; the materials introduce the relevant conventions explicitly. While the running example uses WRDS data familiar to business researchers, the workflow conventions documented here — version control, reproducible pipelines, journal-policy artifacts, publication-grade tables — apply equally to adjacent observational-data fields including economics, political science, and empirical legal studies. After working through the hub and the companion templates, learners should be able to:

* Structure an empirical research project across a Git repository, a local working clone, a cloud-synchronized data directory, and a LaTeX manuscript collaboration platform, with code, data, and manuscript artifacts separated cleanly.
* Use Git and GitHub for everyday research workflows, including committing meaningful changes, branching for alternative specifications, tagging paper versions for journal submissions, and collaborating with coauthors via pull requests.
* Configure a development environment with project-level configuration via a `.env` file, Python virtual environments via `uv` [@uv], and OS-keyring storage of database credentials.
* Implement a five-step empirical pipeline — WRDS data download, transformation, figures, analysis tables, and data-provenance reporting — in R, Python, Stata, or a working combination of the three.
* Produce publication-grade tables in LaTeX, Word, and RTF formats from the same analysis code, integrated into a LaTeX manuscript suitable for journal submission.
* Produce the artifact set required by academic journals' data and code sharing policies, including per-script execution logs, sample-identifier files, and SHA256 file inventories.
* Apply analogous conventions in SAS where required, using the reference macro library provided in the hub.

# Content

The hub repository contains seven in-depth topic chapters (Table 1), and the companion `project-template` ships a five-step empirical pipeline (Table 2). The `overleaf-template` provides a parallel LaTeX manuscript template wired to consume the outputs of `project-template`.

Table: In-depth topic chapters in `example-project`.

| Chapter | Content |
|---:|---|
| Project structure | Storage locations (GitHub, local clone, cloud sync, Overleaf); separation of code, data, and manuscript; folder layout and file-naming conventions. |
| Git and GitHub | Version control workflow for research; commit, branch, and tag conventions; `.gitignore` essentials; collaboration via pull requests. |
| Setting up your IDE | Editor selection across RStudio, VS Code, Cursor, and Positron; per-IDE configuration; AI-assistant integration. |
| Python virtual environments | Distinction between Python and other research languages; system-conflict and permissions concerns; the `uv` tool for environment and dependency management. |
| Environment variables and `.env` | Project-level configuration shared across R, Python, Stata, and SAS. |
| About `AGENTS.md` | Conventions for providing project context to AI coding assistants such as Claude Code, GitHub Copilot, and Cursor. |
| SAS macros | A reference SAS macro library (`MACROS.sas`) and a working example pipeline script demonstrating `%load_env` and integration with the templates' `batch_run_sas()` workflow. |

Table: Pipeline steps in `project-template`.

| Step | Content | Languages |
|---:|---|---|
| 001 Download data | Pulls Compustat fundamentals, CRSP returns, and CCM link tables from WRDS; streams large tables via server-side cursors to bounded-memory parquet files. | R, Python |
| 002 Transform data | Constructs analytical variables, applies sample filters, and computes event-window buy-and-hold abnormal returns. | R, Python |
| 003 Figures | Produces five publication-grade figures via `ggplot2` [@ggplot2] in R and `plotnine` [@plotnine] in Python. | R, Python |
| 004 Analyze data | Produces a sample-selection table, descriptive statistics, a correlation matrix, and a main regression table with fixed effects, exported as LaTeX, Word, and RTF. | R, Python, Stata |
| 005 Data provenance | Exports the sample-identifier file in Parquet and CSV; computes SHA256 hashes for every raw, derived, and output file. | R, Python |

A `run-all.{R,py}` orchestrator chains the steps via a `batch_run()` helper that spawns each script in a fresh child process and writes a uniform plain-text log. When the user has selected a Stata-inclusive language combination, the orchestrator additionally invokes the Stata analysis-and-tables script via a `batch_run_stata()` helper that produces a log of the same shape. The resulting per-script logs, together with the outputs of step 005, constitute the artifact set required by journals' data and code sharing policies.

# Use in the Classroom

The materials are designed for use in graduate-level empirical methods courses and in independent doctoral study. A recommended sequence is to assign the in-depth topic chapters as preparatory reading, have students spin up a personal copy of `project-template` via the GitHub "Use this template" workflow, and complete the pipeline using their selected language combination. A capstone exercise extends the pipeline with an alternative specification on a Git branch and produces a journal-quality manuscript draft using `overleaf-template`. The CC-BY-4.0 license permits instructors at other institutions to adapt and redistribute the materials with attribution.

# Conclusion

The hub and template suite presented here provide a starting point for reproducible empirical research in many social science fields, with conventions and artifact production aligned with the data and code sharing policies adopted by major journals in accounting and finance. The polyglot design accommodates the multi-language reality of social science research, and the materials are designed to be useful both as classroom resources and as a tested skeleton for publication-ready research projects.

# Acknowledgements

The author thanks doctoral students and colleagues who have used and provided feedback on earlier versions of these materials. Many of the underlying examples were developed as part of the research methods used in @weisbrod2019stockholders, @bochkay2022roles, and @larocqueconsensus. Many of the reproducibility conventions documented in these materials are used in the public companion repository for @larocqueconsensus at <https://github.com/eweisbrod/consensus>, which is referenced throughout the hub as a real-world example.

# References
