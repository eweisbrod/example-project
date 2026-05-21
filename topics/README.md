---
title: In-depth topics
nav_order: 6
has_children: true
permalink: /topics/
---

# In-depth topics

Chapter-length notes on individual topics that come up in the templates but
don't fit cleanly into a README. Each file is a standalone reference —
read whichever one you need, in any order. Linked from the
[hub README](../README.md).

## Chapters

The list will grow as topics are written. Linked entries below are
live; unlinked entries are placeholders for content I plan to add.

- **[Project structure for research](project-structure.md)** — the
  three storage locations (GitHub, local clone, cloud sync), why
  code and data must be separate, why the local clone shouldn't be
  inside Dropbox, the recommended folder layout, file-naming
  conventions, and the LaTeX-vs-Word manuscript decision.
- **[Git and GitHub for research projects](git-and-github.md)** —
  Git vs. GitHub, the everyday commit/push/pull workflow, template
  repositories, branching for R&R revisions, tagging paper
  versions, `.gitignore` essentials, and a glossary.
- **[Setting up your IDE](setting-up-your-ide.md)** — what an IDE
  is and the popular ones, why an IDE beats Jupyter notebooks for
  reproducible research code, how IDEs treat a folder as a project,
  the source-control panels in RStudio and VS Code, per-editor
  setup notes, ligature fonts, and AI-assistant integration.
- **[Environment variables and the `.env` file](environment-variables.md)** —
  what an environment variable is, why the templates use `.env`
  instead of hardcoded paths, how each of R / Python / Stata / SAS
  reads it, credentials in `keyring` vs. `.env`, common gotchas.
- **[About AGENTS.md](agents-md.md)** — what the `AGENTS.md` file in each
  repo is, the cross-tool standard behind it, how it interacts with
  `CLAUDE.md`, and why you might want one in your own projects.
- **[SAS macros and `batch_run_sas`](../sas-example/)** — `MACROS.sas`,
  a working SAS script (`002-merge-fdp-data.sas` from the consensus repo),
  and a walkthrough of using `%load_env` + `batch_run_sas()` for
  JAR-style logs.
- **Python virtual environments with `venv` and `uv`** — what a
  Python virtual environment is, why you need one per project, the
  shift from manual `venv` to `uv` for the templates, and how the
  IDE picks up the project's interpreter.