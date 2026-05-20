# Topics

In-depth notes on individual topics that come up in the templates but
don't fit cleanly into a README. Each file is a standalone reference —
read whichever one you need, in any order. Linked from the
[hub README](../README.md).

## Planned topics

The list will grow as topics are written. Linked entries below are
live; unlinked entries are placeholders for content I plan to add.

- **Environment variables and the `.env` file** — what an environment
  variable is, why the templates use `.env` instead of hardcoded
  paths, OS-specific setup, common gotchas.
- **Git and GitHub for research workflows** — using template
  repositories, branching for a research project, working with the
  RStudio Git pane vs. the terminal.
- **WRDS access and credentials** — connecting from R / Python /
  Stata, storing credentials in the OS keyring, the chunked-download
  pattern for very large tables.
- **The `RAW_DATA_DIR` / `DATA_DIR` split** — why the templates
  separate raw external pulls from derived analytical datasets, and
  how that supports replication.
- **AI agents in a reproducible research workflow** — Claude Code,
  GitHub Copilot, AGENTS.md / CLAUDE.md conventions, capturing AI
  contributions for the project record.
- **Reading a `.Rout` log file** — what `R CMD BATCH` produces, how
  it differs from `source()`, and what to look for when something
  goes wrong.
- **Citation management with Zotero and biblatex-chicago** — exporting
  from Zotero with stable citation keys, the `\citet` / `\citep` /
  `\citepos` family.

## Conventions for these notes

Each topic file is named in kebab-case (`environment-variables.md`,
not `EnvironmentVariables.md`). The first line is the topic title as
a level-1 heading. Screenshots go in `topics/img/`. Code blocks use
triple-backtick fences with a language tag (`r`, `python`, `bash`,
etc.) so GitHub's rendering highlights them.
