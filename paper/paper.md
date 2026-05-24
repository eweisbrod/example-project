---
title: 'Reproducible Empirical Research in Accounting and Finance: An open-source teaching hub and template suite'
tags:
  - accounting
  - finance
  - empirical research
  - reproducible research
  - R
  - Python
  - Stata
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

We present an open-source teaching hub and template suite for reproducible empirical research in accounting and finance. The materials are organized as three Git repositories that together cover the workflow from raw database access through publication-grade manuscript production:

- [**`example-project`**](https://github.com/eweisbrod/example-project) — the teaching hub. Contains in-depth chapters on project structure, version control with Git and GitHub, integrated development environment (IDE) setup, Python virtual environments, environment variables and configuration files, AI-assistant integration via `AGENTS.md`, and a SAS macro reference for projects that retain SAS code.
- [**`project-template`**](https://github.com/eweisbrod/project-template) — a GitHub template repository implementing a five-step empirical pipeline (data download, transformation, figures, analysis tables, and provenance reporting) with parallel implementations in **R** and **Python**, plus a **Stata** implementation of the analysis-and-tables step. At first run, the template prompts the user to select a language combination and prunes the unused files.
- [**`overleaf-template`**](https://github.com/eweisbrod/overleaf-template) — a LaTeX manuscript template designed to consume the table and figure outputs of `project-template`, demonstrating `biblatex-chicago` citations, hypothesis-numbering conventions, and a section structure suitable for accounting and finance journals.

The running example throughout the materials is a quarterly earnings-announcement event study using data from Wharton Research Data Services (WRDS) [@bochkay2022roles]. Unexpected earnings, interacted with a same-sign indicator on the seasonal change in sales, are regressed on three-day buy-and-hold abnormal returns. The same regression is implemented in R, Python, and Stata in parallel to demonstrate cross-language consistency in the published tables. All materials are released under the Creative Commons Attribution 4.0 International (CC-BY-4.0) license, and the templates use GitHub's "Use this template" workflow so that instructors and individual researchers can spin up customized copies without forking.

# Statement of Need

Empirical accounting and finance research depends on an interconnected stack of database access (typically WRDS), data manipulation, statistical modeling, and publication-grade table and figure formatting. Formal training in this end-to-end workflow is uncommon in business school doctoral programs, and most researchers in the field do not arrive with formal training in software engineering. Practitioners therefore typically inherit their advisor's scripts or assemble tutorials from disparate sources, with the common outcome that working analyses become difficult for collaborators, reviewers, or future replicators to reproduce.

This gap matters increasingly because accounting and finance journals are formalizing data and code sharing policies modeled on long-established norms in economics. The Journal of Accounting Research's Data and Code Sharing Policy [@JARpolicy] requires submitting authors to provide three artifacts: (1) the code that produces the analytical dataset and the reported tables and figures from raw inputs, (2) a comprehensive log file documenting end-to-end execution, and (3) identifiers of the observations comprising the final sample. Comparable requirements have been adopted at several other major journals in the field. A first-time submitter must therefore acquire not only the substantive skills of empirical research but the workflow skills required to package the research as a reproducible artifact suitable for journal-level scrutiny.

Existing pedagogical resources address parts of this gap. For example, @french2023r and @donoghue2022course cover R programming with applications to financial data. These resources tend to be single-language, focus on the estimation step rather than the surrounding workflow, and do not directly address the journal-policy artifacts. The materials presented here are designed to fill the remaining gap, with three distinguishing features:

1. **Polyglot by design.** A typical accounting or finance project involves at least two of R, Python, and Stata, often inherited from coauthors or required by collaborators. The pipeline template ships parallel implementations in all three languages and allows the user to select any subset at setup. Cross-language consistency is verified by producing the same regression tables via `pyfixest`, `fixest` with `modelsummary`, and `reghdfe` with `estout`.

2. **Journal-policy artifacts produced as a by-product of running the pipeline.** Every pipeline step emits a per-script log file in a uniform plain-text format across all supported languages, and a final provenance step exports sample-identifier files and a content-addressed (SHA256) inventory of every raw, derived, and output file. The resulting artifact set matches what major accounting and finance journals require at submission.

3. **Publication-grade table formatting.** Most graduate programs cover statistical estimation but undertrain the "last mile" of producing journal-quality tables with fixed-effect indicator rows, clustered standard errors, significance markers, and consistent number formatting. The templates produce these tables in all three languages and demonstrate how to integrate the resulting `.tex` files into a LaTeX manuscript via the companion `overleaf-template`.

The materials are designed both as a teaching resource for PhD students and early-career researchers building their first reproducible empirical project, and as a tested skeleton for experienced researchers who want to jumpstart new projects with reproducibility conventions and journal-policy artifacts in place.

# Target Audience and Learning Objectives

The primary audience is PhD students and early-career researchers in accounting, finance, and adjacent business-school disciplines who are building their first reproducible empirical project. A secondary audience is experienced researchers seeking a tested project skeleton with reproducibility conventions already in place. No prior software-engineering training is assumed; the materials introduce the relevant conventions explicitly. After working through the hub and the companion templates, learners should be able to:

* Structure an empirical research project across a Git repository, a local working clone, a cloud-synchronized data directory, and a LaTeX manuscript collaboration platform, with code, data, and manuscript artifacts separated cleanly.
* Use Git and GitHub for everyday research workflows, including committing meaningful changes, branching for alternative specifications, tagging paper versions for journal submissions, and collaborating with coauthors via pull requests.
* Configure a development environment with project-level configuration via a `.env` file, Python virtual environments via `uv`, OS-keyring storage of database credentials, and IDE conventions that travel across collaborators.
* Implement a five-step empirical pipeline — WRDS data download, transformation, figures, analysis tables, and data-provenance reporting — in R, Python, Stata, or a working combination of the three.
* Produce publication-grade tables in LaTeX, Word, and RTF formats from the same analysis code, integrated into a LaTeX manuscript suitable for journal submission.
* Produce the artifact set required by major accounting and finance journals' data and code sharing policies, including per-script execution logs, sample-identifier files, and SHA256 file inventories.
* Apply analogous conventions in SAS where required, using the reference macro library provided in the hub.

# Content

The hub repository contains seven in-depth topic chapters (Table 1), and the companion `project-template` ships a five-step empirical pipeline (Table 2). The `overleaf-template` provides a parallel LaTeX manuscript template wired to consume the outputs of `project-template`.

Table: In-depth topic chapters in `example-project`.

| Chapter | Content |
|---:|---|
| Project structure | Storage locations (GitHub, local clone, cloud sync, Overleaf); separation of code, data, and manuscript; folder layout and file-naming conventions. |
| Git and GitHub | Version control workflow for research; commit, branch, and tag conventions; `.gitignore` essentials; collaboration via pull requests. |
| Setting up your IDE | Editor selection across RStudio, VS Code, Cursor, and Positron; per-IDE configuration; AI-assistant integration; programming-font selection. |
| Python virtual environments | Distinction between Python and other research languages; system-conflict and permissions concerns; the `uv` tool for environment and dependency management. |
| Environment variables and `.env` | Project-level configuration shared across R, Python, Stata, and SAS; credentials stored in the operating-system keyring rather than in plain text. |
| About `AGENTS.md` | Conventions for providing project context to AI coding assistants such as Claude Code, GitHub Copilot, and Cursor. |
| SAS macros | A reference SAS macro library (`MACROS.sas`) and a working example pipeline script demonstrating `%load_env` and integration with the templates' `batch_run_sas()` workflow. |

Table: Pipeline steps in `project-template`.

| Step | Content | Languages |
|---:|---|---|
| 001 Download data | Pulls Compustat fundamentals, CRSP returns, and CCM link tables from WRDS; streams large tables via server-side cursors to bounded-memory parquet files. | R, Python |
| 002 Transform data | Constructs analytical variables, applies sample filters, and computes event-window buy-and-hold abnormal returns. | R, Python |
| 003 Figures | Produces five publication-grade figures via `ggplot2` in R and `plotnine` in Python. | R, Python |
| 004 Analyze data | Produces a sample-selection table, descriptive statistics, a correlation matrix, and a main regression table with fixed effects, exported as LaTeX, Word, and RTF. | R, Python, Stata |
| 005 Data provenance | Exports the sample-identifier file in Parquet and CSV; computes SHA256 hashes for every raw, derived, and output file. | R, Python |

A `run-all.{R,py}` orchestrator chains the steps via a `batch_run()` helper that spawns each script in a fresh child process and writes a uniform plain-text log. When the user has selected a Stata-inclusive language combination, the orchestrator additionally invokes the Stata analysis-and-tables script via a `batch_run_stata()` helper that produces a log of the same shape. The resulting per-script logs, together with the outputs of step 005, constitute the artifact set required by major accounting and finance journals' data and code sharing policies.

# Use in the Classroom

The materials are designed for use in graduate-level empirical methods courses and in independent doctoral study. A recommended sequence is to assign the in-depth topic chapters as preparatory reading, have students spin up a personal copy of `project-template` via the GitHub "Use this template" workflow, and complete the pipeline using their selected language combination. A capstone exercise extends the pipeline with an alternative specification on a Git branch and produces a journal-quality manuscript draft using `overleaf-template`. The CC-BY-4.0 license permits instructors at other institutions to adapt and redistribute the materials with attribution.

# Conclusion

The hub and template suite presented here provide a starting point for reproducible empirical research in accounting and finance, with conventions and artifact production aligned with the data and code sharing policies adopted by major journals in the field. The polyglot design accommodates the multi-language reality of contemporary accounting and finance research, and the materials are designed to be useful both as classroom resources and as a tested skeleton for new research projects.

# Acknowledgements

The author thanks doctoral students and colleagues who have used and provided feedback on earlier versions of these materials. The example analysis was developed alongside @bochkay2022roles, and elements of the project structure draw on conventions developed in @weisbrod2019stockholders.

# References
