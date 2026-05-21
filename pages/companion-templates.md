---
title: Companion templates
nav_order: 2
---

# The companion templates

Pick the template that matches what you're building. Both are GitHub template repositories — click "Use this template" to spin up your own copy.

| Template | What it produces | Languages |
|---|---|---|
| [`project-template`](https://github.com/eweisbrod/project-template) | The empirical research pipeline (download, transform, figures, tables, provenance). Pick a language combination at setup time; the template prunes the rest. | R and Python for every step; Stata for the analyze/tables step (any subset selectable at first run) |
| [`overleaf-template`](https://github.com/eweisbrod/overleaf-template) | The LaTeX manuscript that consumes the figures and tables produced by `project-template`. | LaTeX (Overleaf-compatible) |

The two are designed to be used together: `project-template` writes `.tex` files into its `OUTPUT_DIR`, and `overleaf-template`'s `main.tex` reads them via `\input{}`. They share the same `.env` / `keyring` conventions so figures and tables produced by one slot into the other without configuration.

For information on reporting issues, contributing fixes or improvements, or seeking support, see [Contributing](../CONTRIBUTING.md).
