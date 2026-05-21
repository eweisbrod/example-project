---
title: Project structure
parent: In-depth Topics
nav_order: 1
---

# Project structure for research

An academic research project is made up of several distinct artifacts, each with different storage and collaboration needs. The major pieces:

- **Code** — scripts that turn raw data into the analytical dataset and produce the reported tables and figures.
- **Data** — raw external pulls (WRDS, hand-collected, etc.) and the derived analytical datasets that code produces.
- **The manuscript** — the actual paper being written.

A project also accumulates supporting artifacts: papers collected for the literature review, working memos between coauthors, intermediate outputs that never make it into the published paper, presentation slides, etc. Those don't fit cleanly into any single category and are mostly stored wherever feels natural — often alongside the data in a cloud-sync folder.

This chapter focuses on the three main pieces — **code, data, and manuscript** — and how to organize them with reproducibility in mind. The structure these materials envision uses **four storage locations at once**: a GitHub repository for code, a local clone on your computer where you actually work, a cloud-sync folder (Dropbox / OneDrive / etc.) for data and supporting artifacts, and Overleaf for the LaTeX manuscript if you use one. This convention isn't the only way to organize a project — it's the one the templates throughout this hub are designed around — but it scales cleanly from a first PhD paper to a multi-coauthor R&R.

<details open markdown="block">
<summary>On this page</summary>

1. TOC
{:toc}

</details>

## The four storage locations

Each artifact lives on a very different timescale and benefits from different storage. The split this hub's templates assume:

| Lives in | What it holds | Why |
|---|---|---|
| **GitHub** (the remote repo) | Code, scripts, configuration templates (`.example-env`), the README, `AGENTS.md` / `CLAUDE.md`. *If you don't use Overleaf, the LaTeX paper source goes here too.* | Git is built for line-by-line versioning of small text files. GitHub adds collaboration, issues, and replication-package archival. |
| **Local clone** (a folder on your disk, e.g. `C:/_git/your-project/`) | A working copy of the GitHub repo, plus your local `.env` with machine-specific paths, plus the `log/` directory of execution logs. | This is where you actually work. The clone syncs to GitHub via `git push` and `git pull`. |
| **Cloud sync** (Dropbox / OneDrive / Google Drive) | Raw and derived data, the literature collection, working memos, intermediate outputs. *If you use MS Word for the manuscript instead of LaTeX, the `.docx` lives here.* | Data files are too big and too binary for git. Cloud-sync clients handle them well and share them across collaborators without polluting git history. |
| **Overleaf** (or another LaTeX-collaboration tool) | The LaTeX manuscript source (`main.tex`) and the bibliography (`.bib`), if you use Overleaf. Has its own per-edit version history with Word-style real-time multi-author editing. | Lets coauthors edit the LaTeX in a browser without each installing a LaTeX distribution. Can optionally sync back to a GitHub repo as a backup, but the canonical copy is Overleaf-side. |

**Where the manuscript actually lives is a tool decision**, not a layout decision. LaTeX-via-Overleaf users keep it in Overleaf (location 4). LaTeX-without-Overleaf users keep `.tex` files in git alongside the code (location 1). MS Word users keep `.docx` in cloud sync (location 3). The [LaTeX-vs-Word section below](#the-manuscript-latexoverleaf-vs-microsoft-word) walks through the tradeoffs of that choice.

The structural rule: **code in git, data in cloud sync, manuscript wherever the writing tool keeps it, and the local clone references the data folder via `.env`**. The same code runs on every collaborator's machine because each has their own `.env` pointing at their own copy of the data ([Environment variables and .env](environment-variables.md) covers the mechanics).

## Why code and data must be separate

The temptation when starting a project is to put everything in one folder. Don't.

- **Git treats large binaries badly.** A 4 GB `.parquet` committed to git balloons the repo size, slows every `clone` and `pull`, and never compresses across versions. Cloud-sync handles big binaries gracefully; git fights you over them.
- **Data has a different lifecycle than code.** Code changes line-by-line over months; raw data files are usually written once and read many times. Version control for code matters; version control for data is a different problem, mostly handled by date-stamping filenames (see [Naming files](#naming-files)).
- **Replication packages are easier to assemble.** When you ship code to a journal, you ship just the contents of git. The data goes in a separate archive (or stays restricted, with a sample-identifier file as the bridge). Mixing the two in one folder forces you to disentangle them later.
- **Collaboration scales differently.** A coauthor can clone your repo and verify it builds without needing your 80 GB of WRDS pulls. They run `1-download-data.R` against their own credentials to populate their own `RAW_DATA_DIR`.

## Why the local clone shouldn't be inside Dropbox

This is a specific gotcha worth flagging: **do not put your local git repository inside Dropbox** (or OneDrive, or Google Drive Desktop, etc.).

Git and cloud-sync clients both watch the filesystem for changes. When they fight over the `.git/` folder — Dropbox trying to sync a file while git is mid-write to its packed objects — repositories silently corrupt. The fix when it happens is "re-clone from GitHub and lose any uncommitted work" — fine, but annoying, and the failure mode often shows up days after the corruption began.

The clean separation:

- **Code** in `C:/_git/your-project/` (Windows) or `~/_git/your-project/` (Mac/Linux). Standard local disk, no cloud sync watching it.
- **Data** in `D:/Dropbox/your-project/raw/` and `D:/Dropbox/your-project/derived/`. Dropbox-synced.
- **`.env`** in the code folder, pointing at the Dropbox paths.

Advanced users with strong opinions sometimes put code in cloud sync — git+Dropbox interaction is finicky but not catastrophic if you know what you're doing. For a PhD student starting their first project, just don't.

## Inside the project: the folder layout

Most projects in this hub follow this skeleton (`project-template` ships exactly this):

```
your-project/
├── .env                          # local config, gitignored
├── .example-env                  # committed placeholder
├── .gitignore                    # what NOT to commit
├── README.md                     # what this project is and how to run it
├── AGENTS.md                     # AI assistant context (optional)
├── CLAUDE.md                     # Claude Code config (optional)
├── src/                          # source code, all scripts live here
│   ├── 000-collect-fundq.R       # raw collection (may be several of these)
│   ├── 1-download-data.R         # canonical pipeline starts here
│   ├── 2-transform-data.R
│   ├── 3-figures.R
│   ├── 4-analyze-data.R
│   ├── 5-data-provenance.R
│   ├── run-all.R                 # orchestrator
│   └── utils.R                   # shared helpers
├── log/                          # script execution logs (gitignored)
└── paper/                        # LaTeX source (only if NOT using Overleaf; optional)
    ├── main.tex
    └── Bibliography.bib
```

Raw and derived data live outside this tree, in cloud-sync folders pointed to by `RAW_DATA_DIR` and `DATA_DIR` in `.env`.

`output/` is sometimes inside the project (when outputs are small `.tex` tables and `.png` figures) and sometimes outside in cloud sync (when outputs balloon or you have many of them). The templates default to `OUTPUT_DIR=output` so it lives inside the repo; flip it to an absolute Dropbox path in `.env` if your outputs get large.

## Naming files

Three principles, paraphrased from [Jenny Bryan's *Naming Things*](https://speakerdeck.com/jennybc/how-to-name-files):

1. **Machine readable** — lowercase, hyphens or underscores instead of spaces, no accented characters, no punctuation other than `-` `_` `.`. So `1-download-data.R`, not `1. Download Data.R`.
2. **Human readable** — keywords that describe what the file does. `1-download-data.R` over `script1.R`.
3. **Plays well with default ordering** — numeric prefixes so files sort by execution order. `1-download-data.R`, `2-transform-data.R`, `3-figures.R` line up in any file browser without thinking.

### Numbered scripts (and what to do before the order is known)

Once you know the order of your pipeline, prefixing each file with its position is one of the highest-ROI conventions you can adopt. It tells a reviewer (or future you) exactly what to run when. The templates use `1-`, `2-`, `3-`, … for the canonical pipeline.

But early in a project the order isn't known yet, and you're writing scratchwork. Two patterns work well:

- **`XXX-` or `scratch-` prefixes** for files you're still exploring with. `XXX-explore-fundq.R`, `scratch-pull-test.R`. These sort separately from the numbered pipeline so they don't pretend to be canonical. When a `scratch-` file stabilizes, rename it into the numbered sequence.
- **Multiple `000-` scripts for raw data collection** when there are several independent pulls. `000-collect-wrds.R`, `000-collect-bloomberg.R`, `000-collect-factset.R`. Zero signals "before the pipeline starts" — these run once each, write to `RAW_DATA_DIR`, and aren't re-executed on every run-all. Then `1-` is the first script that operates on the collected raw data.

### Dated artifacts

For data files specifically, embedding a date in the filename solves a different problem: WRDS data changes over time (Compustat backfills, IBES restates, etc.), and a reviewer running your code two years from now will get different numbers than you did. Date-stamping the raw file (`fundq_2025-07-18.parquet`) preserves which snapshot the paper's results come from. `YYYY-MM-DD` is the most defensible format; `MMDDYYYY` works too — what matters is consistency within a project.

## The manuscript: LaTeX/Overleaf vs. Microsoft Word

Both work for academic writing. They optimize for very different things.

**LaTeX (typically via Overleaf):**

- **Pros.** Equation rendering is unmatched. Bibliography management via BibTeX is integrated and reproducible. Cross-references (table/figure/equation numbering) update automatically. The `.tex` source is plain text, so it lives in git and diffs cleanly. Overleaf provides Word-style real-time collaboration. The `.tex` table files your pipeline produces (`\input{}`-ed into the manuscript) keep results and prose in sync — re-run the pipeline and the next compile shows the new numbers. The hub's [`overleaf-template`](https://github.com/eweisbrod/overleaf-template) is built around exactly this workflow.
- **Cons.** Steeper initial learning curve. Compilation errors can be cryptic at first. Tracked changes are awkward (LaTeX-aware diff tools exist but aren't as smooth as Word's). Some senior coauthors will outright refuse to write in LaTeX.

**Microsoft Word:**

- **Pros.** Universal — every collaborator has it. Tracked Changes and Comments are mature. WYSIWYG editing has no learning curve. Some journals' direct-submission systems expect `.docx`.
- **Cons.** Binary file format is unfriendly to git (you can commit `.docx` but you can't meaningfully diff revisions). Equation editor is clunky. Bibliography management requires external tools (Mendeley, Zotero, EndNote). Cross-references break in confusing ways. Files occasionally corrupt. Filename-version sprawl (`paper_v3_FINAL_2_jw-edits.docx`) is a real cost over the life of a paper.

**The hub's pragmatic answer:** the R and Stata implementations of `project-template` produce **both** `.tex` and `.docx`/`.rtf` outputs of every table. The LaTeX version slots into Overleaf for LaTeX-using authors; the `.docx`/`.rtf` slots into Word for Word-using coauthors. If your senior coauthor insists on Word, you can still keep your pipeline LaTeX-native and hand them the `.docx`.

## Files at the project root

A few specific files almost always live at the project root, alongside `src/`:

- **`README.md`** — what this project is and how to run it. Should answer "what does this code do?" and "how do I run it?" without making the reader open any other file.
- **`AGENTS.md`** — AI assistant context. Even if you don't use AI tools, AGENTS.md is good complementary documentation. See [About AGENTS.md](agents-md.md) for the full story.
- **`CLAUDE.md`** — Claude Code-specific configuration that imports AGENTS.md. Skip if you don't use Claude Code.
- **`.env`** — local configuration (paths, etc.). Gitignored. See [Environment variables and .env](environment-variables.md).
- **`.example-env`** — committed placeholder showing what variables `.env` should contain.
- **`.gitignore`** — what NOT to commit (see below).
- **`LICENSE`** — what others are allowed to do with your code. Pick one explicitly rather than leaving it blank.

## `.gitignore` essentials for research projects

A research project accumulates a lot of files that shouldn't be in git: raw data downloads, machine-specific config, log files, build artifacts, OS clutter. The `.gitignore` file at the project root lists patterns Git should never track.

A defensive baseline:

```gitignore
# Secrets and machine-specific config
.env

# Execution logs and outputs (regenerable)
log/
output/

# Large data files
*.parquet
*.csv
*.dta
*.sas7bdat
*.feather

# Editor and OS clutter
.DS_Store
Thumbs.db
.vscode/
.idea/
*.swp

# Language-specific build artifacts
__pycache__/
.Rproj.user/
.Rhistory
```

Useful rule of thumb: **anything that can be regenerated by running the code shouldn't be in git**. Logs regenerate. Derived parquets regenerate. The `output/` files regenerate. None of those belong in version control.

`*.csv` is a judgment call — if your project has small input CSVs (like a hand-curated list of tickers) that should travel with the code, you'll want to commit those specific files. The pattern above ignores all `.csv` by default; commit exceptions explicitly with `git add -f <file>`.

## A worked example: the project tree

A quarterly earnings-announcement event study, end to end:

```
your-project/                              # local clone, NOT inside Dropbox
├── .env                                    # local; gitignored
├── .example-env                            # committed
├── .gitignore
├── README.md
├── AGENTS.md
├── src/
│   ├── 000-collect-fundq.R                 # raw collection (could be several)
│   ├── 000-collect-ibes.R
│   ├── 1-download-data.R                   # canonical pipeline starts here
│   ├── 2-transform-data.R
│   ├── 3-figures.R
│   ├── 4-analyze-data.R
│   ├── 5-data-provenance.R
│   ├── run-all.R
│   └── utils.R
├── log/                                    # populated by run-all; gitignored
│   ├── 1-download-data.Rout
│   ├── 2-transform-data.Rout
│   └── ...
└── paper/                                  # LaTeX source (optional, alt. is Overleaf)
    ├── main.tex
    └── Bibliography.bib
```

And in cloud sync (Dropbox), outside the project tree:

```
D:/Dropbox/your-project/
├── raw/                                    # RAW_DATA_DIR in .env
│   ├── fundq_2025-07-18.parquet
│   ├── ibes_surpsum_2025-07-18.parquet
│   └── ...
├── derived/                                # DATA_DIR in .env
│   ├── regdata.parquet
│   ├── figure-data.parquet
│   └── ...
├── output/                                 # OUTPUT_DIR in .env (or kept in-repo)
│   ├── table-summary.tex
│   ├── figure-event-study.png
│   └── ...
├── lit/                                    # papers you're reading
└── memos/                                  # working notes shared with coauthors
```

Each collaborator points their `.env` at their own copy of the Dropbox folders. The code in git is identical for everyone. Run `git pull`; their machine reproduces yours.

## See also

- [Environment variables and the `.env` file](environment-variables.md) — the mechanism that makes the same code run against three different filesystems.
- [Git and GitHub for research projects](git-and-github.md) — the version-control workflow that ties the local clone to the remote repo.
- [About AGENTS.md](agents-md.md) — what to put in the `AGENTS.md` at your project root.
- [Jenny Bryan, *Naming Things*](https://speakerdeck.com/jennybc/how-to-name-files) — the canonical reference for file naming.
- [Jenny Bryan, *What They Forgot to Teach You About R*](https://rstats.wtf/) — broader project-organization wisdom for R users.
