---
title: Contributing
nav_order: 9
---

# Contributing

Thanks for your interest in this teaching hub. It is intentionally a
small, maintainer-driven project — Eric Weisbrod (University of Kansas)
owns the materials and is the single steward. That said, outside
contributions are welcome and several kinds are particularly useful:

- **Typo fixes, broken links, clarifications** in any of the READMEs,
  the AGENTS.md files, or the JOSE paper.
- **Bug reports** for the pipeline scripts in `project-template`
  (download, transform, figures, analyze, provenance) or the LaTeX
  template in `overleaf-template`.
- **Suggestions for new advanced-topic briefings, additional
  templates, or improvements to the pedagogical sequence.**


## Where to file

The teaching materials live across **three** repositories. File
contributions and issues in the repo whose content is actually
affected:

| Topic | Repo |
|---|---|
| Anything in the hub README, AGENTS.md, JOSE paper, or `sas-example/` | [`example-project`](https://github.com/eweisbrod/example-project) |
| Pipeline scripts (R / Python / Stata), `utils.{R,py}`, `run-all.{R,py}`, `project_setup`, `batch_run` | [`project-template`](https://github.com/eweisbrod/project-template) |
| LaTeX paper template, `main.tex`, `Bibliography.bib` | [`overleaf-template`](https://github.com/eweisbrod/overleaf-template) |

If you're not sure which repo applies, file in `example-project` and
it can be moved.

## Reporting issues

1. Search the repo's existing issues first to avoid duplicates.
2. Open a new issue describing:
   - **What you ran.** Which script, which language combo, which
     section of the LaTeX template.
   - **What happened.** Paste the relevant error message, or the
     last 20 lines of the relevant log file (`log/<script>.Rout`,
     `log/<script>.log`, etc.).
   - **What you expected to happen.**
   - **Your environment.** OS, R version, Python version (via
     `uv --version` if relevant), Stata version, and which
     language combination was selected at `project_setup()`.

For bugs that depend on WRDS data, you don't need to share data —
just describe which table you were pulling and which filter you applied.

## Suggesting changes (pull requests)

1. Fork the affected repo on GitHub.
2. Create a feature branch off `main`:
   `git checkout -b fix/short-description`
3. Make your changes. For code: keep style consistent with the
   surrounding file (roxygen2 / Google-style docstrings; native pipe
   `|>` in R; polars in Python; the conventions are documented in
   each repo's `AGENTS.md`).
4. If your change touches the pipeline, run the affected step end-to-end
   on your own data and confirm the resulting log file looks reasonable.
5. Push the branch and open a pull request against `main`. Describe
   the motivation and any open questions in the PR body.

PRs that add value but don't fit the maintainer's current direction
may be declined or asked to remain as forks. That isn't a comment
on the quality of the work — it's a maintainability constraint for
a single-person project.

## Seeking support

Three channels, in order of preference:

1. **A GitHub issue** on the relevant repo. Public, searchable,
   helps the next person who hits the same problem.
2. **GitHub Discussions** on `example-project` for open-ended
   questions (workflow, course-design feedback, how-do-I-do-X-with-
   this-template) where the answer isn't a bug fix.
3. **Email** to the maintainer for anything that can't be discussed
   in public. The address is on the maintainer's [KU Business School profile](https://business.ku.edu/people/eric-weisbrod).

The maintainer is a full-time faculty member — response times will
vary, especially during teaching semesters.

## A note on AI-assisted contributions

These materials are themselves built using generative AI tools as
part of the workflow (see the AGENTS.md and CLAUDE.md files in each
repo), and PRs developed with the help of AI are welcome. Two
expectations:

- **You are responsible for the content of your PR**, whether or not
  AI assisted in producing it. This includes catching hallucinated
  function names, made-up citation keys, and incorrect facts. Use of
  AI is not an excuse for errors.
- **Never include a bibliography citation you have not personally
  verified.** AI-generated citation keys frequently point at papers
  that do not exist or have garbled metadata; check the bib file
  before submitting.

## Code of conduct

Be respectful, assume good faith, and keep discussion focused on the
work. Harassment, derogatory language, or off-topic personal attacks
will result in the issue being closed or the offender being blocked.
This is a public-facing project for the academic community; the
standard expected is that of a journal review process.
