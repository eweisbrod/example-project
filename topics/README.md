---
title: Topics
nav_order: 3
has_children: true
permalink: /topics/
---

# Topics

In-depth notes on individual topics that come up in the templates but
don't fit cleanly into a README. Each file is a standalone reference —
read whichever one you need, in any order. Linked from the
[hub README](../README.md).

## Planned topics

The list will grow as topics are written. Linked entries below are
live; unlinked entries are placeholders for content I plan to add.


- **[Environment variables and the `.env` file](environment-variables.md)** —
  what an environment variable is, why the templates use `.env`
  instead of hardcoded paths, OS-specific setup, common gotchas.
- **WRDS access and credentials** — connecting from R / Python /
  Stata, storing credentials in the OS keyring, the chunked-download
  pattern for very large tables.
- **The `RAW_DATA_DIR` / `DATA_DIR` split** — why the templates
  separate raw external pulls from derived analytical datasets, and
  how that supports replication.
- **AI agents in a reproducible research workflow** — Claude Code,
  GitHub Copilot, AGENTS.md / CLAUDE.md conventions, capturing AI
  contributions for the project record.


## Conventions for these notes

Each topic file is named in kebab-case (`environment-variables.md`,
not `EnvironmentVariables.md`). The first line is the topic title as
a level-1 heading. Screenshots go in `topics/img/`. Code blocks use
triple-backtick fences with a language tag (`r`, `python`, `bash`,
etc.) so GitHub's rendering highlights them.
