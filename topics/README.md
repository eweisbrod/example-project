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

- **[Environment variables and the `.env` file](environment-variables.md)** —
  what an environment variable is, why the templates use `.env`
  instead of hardcoded paths, OS-specific setup, common gotchas.
- **[About AGENTS.md](agents-md.md)** — what the `AGENTS.md` file in each
  repo is, the cross-tool standard behind it, how it interacts with
  `CLAUDE.md`, and why you might want one in your own projects.
- **[SAS macros and `batch_run_sas`](../sas-example/)** — `MACROS.sas`,
  a working SAS script (`002-merge-fdp-data.sas` from the consensus repo),
  and a walkthrough of using `%load_env` + `batch_run_sas()` for
  JAR-style logs.
- **WRDS access and credentials** — connecting from R / Python /
  Stata, storing credentials in the OS keyring, the chunked-download
  pattern for very large tables.
- **The `RAW_DATA_DIR` / `DATA_DIR` split** — why the templates
  separate raw external pulls from derived analytical datasets, and
  how that supports replication.


## Conventions for these notes

Each topic file is named in kebab-case (`environment-variables.md`,
not `EnvironmentVariables.md`). The first line is the topic title as
a level-1 heading. Screenshots go in `topics/img/`. Code blocks use
triple-backtick fences with a language tag (`r`, `python`, `bash`,
etc.) so GitHub's rendering highlights them.
