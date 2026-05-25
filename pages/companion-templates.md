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


## A real-world example

For a glimpse of what a finished project built on these conventions looks like, see [Larocque, Watkins, and Weisbrod (forthcoming)](https://doi.org/10.1111/1475-679x.70072), "Consensus? An Examination of Differences in Earnings Information Across Forecast Data Providers" (*Journal of Accounting Research*, in production). The paper's public [companion repository on GitHub](https://github.com/eweisbrod/consensus) applies the same patterns the templates here demonstrate, across a multi-language (R, Stata, SAS) production project that satisfies JAR's [Data and Code Sharing Policy](jar-data-policy.md).
