# AGENTS.md - AI Assistant Context for example-project

> **What is this file?** AGENTS.md is an emerging open standard for providing
> AI coding assistants with project context. It is supported by Claude Code,
> Cursor, Windsurf, GitHub Copilot, and other AI tools. Think of it as a
> README for AI — it tells any AI assistant how this repository is organized
> and what its role is. See the
> [README section on AGENTS.md](README.md#about-agentsmd) for more details.

## Repo role

This repository is the **hub** for a set of teaching materials on running a
reproducible empirical project in Accounting / Finance. It is not the home
of the example pipeline code; that lives in three companion repositories:

- [`project-template-r`](https://github.com/eweisbrod/project-template-r) —
  R-only event-study pipeline (recommended starting point for R users).
- [`project-template`](https://github.com/eweisbrod/project-template) —
  Polyglot version: Python download/transform plus R/Python/Stata parallel
  implementations of figures and tables.
- [`overleaf-template`](https://github.com/eweisbrod/overleaf-template) —
  LaTeX paper template demonstrating the tables and figures.

This hub repo holds the JOSE paper, the README that introduces the
materials, the assets (screenshots, slide deck), and the Overleaf paper
source under `overleaf/`.

## Repo structure

```
example-project/
├── _config.yml          # GitHub Pages config (renders README at the .io URL)
├── AGENTS.md            # This file
├── CLAUDE.md            # Claude Code config (imports AGENTS.md)
├── README.md            # Hub landing page
├── LICENSE
├── assets/              # Screenshots and images for documentation
│   ├── images/          # Inline images referenced from README
│   ├── theme/           # Optional RStudio theme + font for teaching
│   ├── Paper_Template.pdf  # Example PDF showing the LaTeX tables
│   └── slides.pptx      # In-person teaching deck
└── overleaf/
    └── main.tex         # JOSE paper source (also tracked in overleaf-template)
```

There is no `src/` here; that lived in this repo before the templates were
split out. The templates are now the canonical home of the pipeline code.

## When working in this repo

- The repo is content-only (markdown, LaTeX, screenshots) — there is no
  pipeline code to run.
- When the user asks to update the pipeline, recognize that they likely
  mean the templates and ask which one. Do not recreate `src/` here.
- When the user asks to update the Overleaf paper, the canonical text
  lives in `overleaf-template`. The `overleaf/` folder here may be a
  duplicate / snapshot — confirm before editing.
- README links to all three template repos and to the JOSE paper. Keep
  those links current if URLs change.

## Common pitfalls

- **No code lives here.** If a session starts here and the task is about
  the pipeline (download, transform, regression, tables), the work
  belongs in `project-template-r` or `project-template`. Switch
  directories or ask the user which template the change is for.
- **The `overleaf/` folder vs. the `overleaf-template` repo.** The latter
  is the canonical Overleaf project (synced to Overleaf via Git). Treat
  this folder as a snapshot unless the user confirms otherwise.
