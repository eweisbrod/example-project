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
of the example pipeline code; that lives in two companion repositories:

- [`project-template`](https://github.com/eweisbrod/project-template) —
  the research-pipeline template. Ships parallel R and Python
  implementations of every numbered step (download, transform, figures,
  analyze, provenance), plus a Stata implementation of the
  analyze/tables step that reads the `.dta` written by either R or
  Python's transform. On first run, `project_setup()` asks the user to
  pick a language combination (Full R / Full Python / Python + R /
  Python + Stata / R + Stata / all three) and prunes the irrelevant
  files. The previous `project-template-r` repository has been sunset;
  option 1 (Full R) of `project-template` produces an identical R-only
  skeleton.
- [`overleaf-template`](https://github.com/eweisbrod/overleaf-template) —
  LaTeX paper template demonstrating the tables and figures.

This hub repo holds the JOSE paper, the README that introduces the
materials, and the SAS reference macros under `sas-example/`. The
LaTeX paper source itself lives in the `overleaf-template` companion
repo, not here — see the pointer to it in the bullet list above.

## Repo structure

```
example-project/
├── _config.yml          # GitHub Pages config (renders README at the .io URL)
├── AGENTS.md            # This file
├── CLAUDE.md            # Claude Code config (imports AGENTS.md)
├── CONTRIBUTING.md      # Issues, PRs, support channels
├── LICENSE
├── README.md            # Hub landing page
├── paper/               # JOSE paper source for example-project itself
│   ├── paper.md
│   └── paper.bib
└── sas-example/         # SAS macros + README, since neither template ships SAS
    ├── MACROS.sas       # Working SAS macro file (load_env, tddays, winsor, ff12/49, ...)
    └── README.md        # How to use + SAS batch-mode gotchas
```

There is no `src/` here; that lived in this repo before the templates were
split out. The templates are now the canonical home of the pipeline code.
`sas-example/` is the one exception — neither template ships SAS code, so
the SAS reference macros live in the hub as a copy-pasteable starting point.

## When working in this repo

- The repo is content-only (markdown, LaTeX, screenshots) — there is no
  pipeline code to run.
- When the user asks to update the pipeline, recognize that they likely
  mean the templates and ask which one. Do not recreate `src/` here.
- When the user asks to update the Overleaf paper, switch into the
  `overleaf-template` companion repo — the LaTeX source is not
  duplicated in this hub.
- README links to both template repos and to the JOSE paper. Keep
  those links current if URLs change.

## Common pitfalls

- **No code lives here.** If a session starts here and the task is about
  the pipeline (download, transform, regression, tables), the work
  belongs in `project-template`. Switch directories before editing.
- **The LaTeX paper isn't here either.** It lives in the
  `overleaf-template` companion repo. There used to be a snapshot
  copy under `overleaf/` in this hub; it was removed to avoid
  divergence.
