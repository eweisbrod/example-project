---
title: Project structure
parent: In-depth topics
nav_order: 1
---

# Project structure for research

An academic research project is made up of several distinct artifacts, each with different storage and collaboration needs. The major pieces:

- **Code** — scripts that turn raw data into the analytical dataset and produce the reported tables and figures.
- **Data** — raw external pulls (WRDS, hand-collected, etc.) and the derived analytical datasets that code produces.
- **The manuscript** — the actual paper being written.

A project also accumulates supporting artifacts: papers collected for the literature review, working memos between coauthors, intermediate outputs that never make it into the published paper, presentation slides, etc. Those don't fit cleanly into any single category and are mostly stored wherever feels natural — often alongside the data in a cloud-sync folder.

This chapter focuses on the three main pieces — **code, data, and manuscript** — and how to organize them with reproducibility in mind. The template materials envision a **four location structure**: a GitHub repository for code, a local clone on your computer where you actually work, a cloud-sync folder (Dropbox / OneDrive / etc.) for data and supporting artifacts, and Overleaf for the LaTeX manuscript if you use one. This convention isn't the only way to organize a project — it's the one the templates throughout this hub are designed around — but it scales cleanly from a first PhD paper to a multi-coauthor R&R.

<details open markdown="block">
<summary>On this page</summary>

1. TOC
{:toc}

</details>

## The four storage locations

Each artifact lives on a very different timescale and benefits from different storage. The split this hub's templates assume:

| Lives in | What it holds | Why |
|---|---|---|
| **GitHub** (the remote repo) | Code, scripts, configuration templates (`.example-env`), the README, `AGENTS.md` / `CLAUDE.md`. *If you don't use Overleaf, the LaTeX paper source goes here too.* | Git is built for line-by-line versioning of small text files. GitHub adds collaboration, issues, and other tools. |
| **Local clone** (a folder on your disk, e.g. `C:/_git/your-project/`) | A working copy of the GitHub repo, plus your local `.env` with machine-specific paths (see the companion chapter **[Environment variables and the `.env` file](environment-variables.md)**), plus the `log/` directory of execution logs. | This is where you actually work. The clone syncs to GitHub via `git push` and `git pull`. |
| **Cloud sync** (Dropbox / OneDrive / Google Drive) | Raw and derived data, the literature collection, working memos, intermediate outputs. *If you use MS Word for the manuscript instead of LaTeX, the `.docx` lives here.* | Data files are too big and too binary for git. Cloud-sync clients handle them well and share them across collaborators without polluting git history. |
| **Overleaf** (or another LaTeX-collaboration tool) | The LaTeX manuscript source (`main.tex`) and the bibliography (`.bib`), if you use Overleaf. Has its own per-edit version history with Word-style real-time multi-author editing. | Lets coauthors edit the LaTeX in a browser without each installing a LaTeX distribution. Can optionally sync back to a GitHub repo as a backup, but the canonical copy is Overleaf-side. |

**Where the manuscript actually lives is a tool decision**, not a layout decision. LaTeX-via-Overleaf users keep it in Overleaf (location 4). LaTeX-without-Overleaf users keep `.tex` files in git alongside the code (location 1). MS Word users keep `.docx` in cloud sync (location 3). The [LaTeX-vs-Word section below](#the-manuscript-latexoverleaf-vs-microsoft-word) walks through the tradeoffs of that choice.



## Why code and data must be separate

The temptation when starting a project is to put everything in one folder. Don't.

- **Code belongs in Git / GitHub.** Code is plain text that benefits enormously from line-by-line version history, branching for alternative specifications, and the off-site backup and searchability GitHub provides for free. If "Git" or "GitHub" are new terms see [Git and GitHub for research projects](git-and-github.md), which covers what they are and the everyday commit/push/pull workflow. The rest of this section assumes code lives in a Git repo on GitHub.
- **Git treats large binaries badly.** A 4 GB `.parquet` committed to git balloons the repo size, slows every `clone` and `pull`, and never compresses across versions. Cloud-sync handles big binaries gracefully; git fights you over them.
- **Sensitive or restricted data has different storage requirements.** Some data can't legally live in regular cloud sync: human-subjects data under IRB protocol, restricted-use Census microdata, certain proprietary feeds whose terms prohibit re-sharing. For these cases the data folder may need to sit on an institutional secure server, an encrypted local volume, or a special-purpose enclave instead of Dropbox or OneDrive. The code-data separation still works the same way — your `.env` just points at the secure location, and the code stays in Git on GitHub as usual.
- **Replication packages are easier to assemble.** When you ship code to a journal, you ship just the contents of git. The data goes in a separate archive (or stays restricted, with a sample-identifier file as the bridge). Mixing the two in one folder forces you to disentangle them later.
- **Your IDE works one folder at a time.** Modern editors — VS Code, RStudio, Cursor — open a folder and treat its contents as the unit of work: they set the working directory there, show its files in the explorer pane, wire up Git integration against the repo at the folder's root, and run scripts relative to it. (IDEs use the word "project" for that folder — that's their term, narrower than how this chapter uses it. In our terms, what the IDE calls a "project" is the repo.) Keeping code *inside* the repo and data *outside* it gives the IDE a tight, focused view of just the source you're editing without cluttering the file tree. See [Setting up your IDE](setting-up-your-ide.md) for the per-editor specifics (RStudio's `.Rproj`, VS Code's `.vscode/`, ligature fonts, AI-assistant integration).


## Why the local clone shouldn't be inside Dropbox

This is a specific gotcha worth flagging: **do not put your local git repository inside Dropbox** (or OneDrive, or Google Drive Desktop, etc.).

Git and cloud-sync clients both watch the filesystem for changes. When they fight over the `.git/` folder — Dropbox trying to sync a file while git is mid-write to its packed objects — repositories silently corrupt. 

The clean separation:

- **Code** within a git repository folder somewhere like `C:/_git/your-project/` (Windows) or `~/_git/your-project/` (Mac/Linux). Standard local disk, no cloud sync watching it. The templates keep scripts in a `src/` subfolder of the repo root.
- **Data** in `D:/Dropbox/your-project/data/raw/` and `D:/Dropbox/your-project/data/derived/`. Dropbox-synced.
- **`.env`** at the repo root, pointing at the Dropbox paths. Modern IDEs open the repo root as the working directory, so scripts running in the IDE find `.env` automatically.


## Inside the repo: the folder layout

The companion templates in this hub ship this repo skeleton, and any project built on top of one of them inherits it:

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
│   ├── 001-download-data.R         # canonical pipeline starts here
│   ├── 002-transform-data.R
│   ├── 003-figures.R
│   ├── 004-analyze-data.R
│   ├── 005-data-provenance.R
│   ├── run-all.R                 # orchestrator
│   └── utils.R                   # shared helpers
├── log/                          # script execution logs (gitignored)
└── paper/                        # LaTeX source (only if NOT using Overleaf; optional)
    ├── main.tex
    └── Bibliography.bib
```

Raw and derived data live outside this tree, in cloud-sync folders pointed to by `RAW_DATA_DIR` and `DATA_DIR` in `.env`.

`output/` is sometimes inside the project (when outputs are small `.tex` tables and `.png` figures) and sometimes outside in cloud sync (when outputs balloon or you have many of them). The templates default to `OUTPUT_DIR=output` so it lives inside the repo; flip it to a Dropbox path or another absolute file path in `.env` if you prefer to store output in cloud sync or another location.

### Files at the repo root

A few specific files almost always live at the repo root, alongside `src/`:

- **`README.md`** — what this project is and how to run it. Should answer "what does this code do?" and "how do I run it?" without making the reader open any other file.
- **`AGENTS.md`** — AI assistant context. Even if you don't use AI tools, AGENTS.md is good complementary documentation. See [About AGENTS.md](agents-md.md) for the full story.
- **`CLAUDE.md`** — Claude Code-specific configuration that imports AGENTS.md. Skip if you don't use Claude Code.
- **`.env`** — local configuration (paths, etc.). Gitignored. See [Environment variables and .env](environment-variables.md).
- **`.example-env`** — committed placeholder showing what variables `.env` should contain.
- **`.gitignore`** — what NOT to commit. See [Git and GitHub for research projects](git-and-github.md#gitignore-for-research-projects) for a defensive baseline.
- **`LICENSE`** — what others are allowed to do with your code. Pick one explicitly rather than leaving it blank.

### Numbered scripts (and what to do before the order is known)

Once you know the order of your pipeline, prefixing each file with its position is one of the highest-ROI conventions you can adopt. It tells a reviewer (or future you) exactly what to run when. The templates use `1-`, `2-`, `3-`, … for the canonical pipeline.

But early in a project the order isn't known yet, and you're writing scratchwork. Two patterns work well:

- **`XXX-` or `scratch-` prefixes** for files you're still exploring with. `XXX-explore-fundq.R`, `scratch-pull-test.R`. These sort separately from the numbered pipeline so they don't pretend to be canonical. When a `scratch-` file stabilizes, rename it into the numbered sequence.
- **Multiple `000-` scripts for raw data collection** when there are several independent pulls. `000-collect-wrds.R`, `000-collect-bloomberg.R`, `000-collect-factset.R`. Zero signals "before the pipeline starts" — these run once each, write to `RAW_DATA_DIR`, and aren't re-executed on every run-all. Then `001-` is the first script that operates on the collected raw data.

## Naming files

Three principles, paraphrased from [Jenny Bryan's *Naming Things*](https://speakerdeck.com/jennybc/how-to-name-files):

1. **Machine readable** — lowercase, hyphens or underscores instead of spaces, no accented characters, no punctuation other than `-` `_` `.`. So `001-download-data.R`, not `1. Download Data.R`.
2. **Human readable** — keywords that describe what the file does. `001-download-data.R` over `script1.R`.
3. **Plays well with default ordering** — numeric prefixes so files sort by execution order. `001-download-data.R`, `002-transform-data.R`, `003-figures.R` line up in any file browser without thinking.

### Don't put dates in filenames

A tempting pattern when starting a project is to embed a date in raw-data filenames — `fundq_2025-07-18.parquet`, `ibes_2025-07-18.parquet` — on the theory that the date preserves which snapshot the paper's results came from. The underlying concern is real: data vintages change over time (e.g., Compustat backfills, error corrections, split adjustments, etc.), and a reviewer running your code two years from now will get different numbers than you did. But date-stamping the filename is the wrong fix.

- **It breaks every script that reads the file each time you refresh the data.** Every reference to `fundq_2025-07-18.parquet` has to be hunt-and-replaced to `fundq_2025-12-01.parquet` next quarter, and again the quarter after. That defeats the entire point of using `.env` and a fixed project structure to keep paths out of the analysis code.
- **It re-creates the filename-sprawl problem git was supposed to solve.** It's the data-file analog of `paper_v3_FINAL_ew-edits.docx`: a folder full of nearly-identical filenames and no clean record of which one is the canonical version for a given paper draft.
- **It conflates two different kinds of metadata.** "When was this snapshot pulled" is metadata *about* a file; "what's the file called" is its name. Folding the two together muddles the distinction.

The cleaner approach: **use stable filenames** (`fundq.parquet`, not `fundq_<date>.parquet`) and record snapshot dates somewhere else.

- The `005-data-provenance.{R,py}` step in the templates writes the SHA256 hash of every raw and derived file to its log. That log *is* your snapshot pin — a reviewer running your code two years from now whose `fundq.parquet` has a different SHA256 knows the underlying data has shifted, and yours hasn't.
- **Archiving old vintages** is one legitimate use of dates in raw-data naming. When you decide to refresh your sample and re-pull raw data, you may want to copy the current contents of `RAW_DATA_DIR` into a dated archive subfolder (e.g., `RAW_DATA_DIR/archive/2025-07-18/`) *before* re-running `001-download-data`. The live pipeline keeps reading `fundq.parquet` at its stable path; the archived vintage sits alongside as a reference you can diff against if the refreshed results unexpectedly change. The principle behind this: stamp the date when something becomes *historical*, not while it's still actively in use.

You'll see dated filenames in some real-world projects (including some referenced from this hub) — that pattern is usually inherited from an older codebase or a coauthor convention, not something to copy into a project starting fresh.

## The manuscript: LaTeX/Overleaf vs. Microsoft Word

Both work for academic writing. They optimize for very different things.

**LaTeX (typically via Overleaf):**

- **Pros.** Equation rendering is unmatched. Bibliography management via BibTeX is integrated and reproducible. Cross-references (table/figure/equation numbering) update automatically. The `.tex` source is plain text, so it lives in git and diffs cleanly. Overleaf provides Word-style real-time collaboration. The `.tex` table files your pipeline produces (`\input{}`-ed into the manuscript) keep results and prose in sync — re-run the pipeline and the next compile shows the new numbers. The hub's [`overleaf-template`](https://github.com/eweisbrod/overleaf-template) is built around exactly this workflow.
- **Cons.** Steeper initial learning curve. Some senior coauthors will outright refuse to write in LaTeX. Compilation errors can be cryptic at first. Tracked changes are awkward (Overleaf has tracked changes but they aren't as smooth as Word's). With that said, tracked changes are often unnecessary or redundant alongside either Git version control or Overleaf's revision history. 

**Microsoft Word:**

- **Pros.** Universal — every collaborator has it. Tracked Changes and Comments are mature. WYSIWYG editing has no learning curve. 
- **Cons.** Binary file format is unfriendly to git (you can commit `.docx` but you can't meaningfully diff revisions). Equation editor is clunky. Bibliography management requires external tools (Mendeley, Zotero, EndNote). Cross-references break in confusing ways. Files occasionally corrupt. Filename-version sprawl (`paper_v3_FINSAL_2_jw-edits.docx`) is a real cost over the life of a paper.

{: .tip-title }
> Flexible Project Template
>
> The R and Stata implementations of `project-template` produce **both** `.tex` and `.docx`/`.rtf` outputs of every table. The LaTeX version slots into Overleaf for LaTeX-using authors; the `.docx`/`.rtf` slots into Word for Word-using coauthors. If your senior coauthor insists on Word, you can still keep your pipeline LaTeX-native and hand them the `.docx`.


## A worked example: the repo tree

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
│   ├── 001-download-data.R                   # canonical pipeline starts here
│   ├── 002-transform-data.R
│   ├── 003-figures.R
│   ├── 004-analyze-data.R
│   ├── 005-data-provenance.R
│   ├── run-all.R
│   └── utils.R
├── log/                                    # populated by run-all; gitignored
│   ├── 001-download-data.Rout
│   ├── 002-transform-data.Rout
│   └── ...
└── paper/                                  # LaTeX source (optional, alt. is Overleaf)
    ├── main.tex
    └── Bibliography.bib
```

And in cloud sync (Dropbox), outside the repo:

```
D:/Dropbox/your-project/
├── data/
│   ├── raw/                                # RAW_DATA_DIR in .env
│   │   ├── fundq.parquet
│   │   ├── ibes_surpsum.parquet
│   │   └── ...
│   └── derived/                            # DATA_DIR in .env
│       ├── regdata.parquet
│       ├── figure-data.parquet
│       └── ...
├── output/                                 # OUTPUT_DIR in .env (or kept in-repo)
│   ├── table-summary.tex
│   ├── figure-event-study.png
│   └── ...
├── papers/                                 # papers you're reading
└── memos/                                  # working notes shared with coauthors
```

Each collaborator points their `.env` at their own copy of the Dropbox folders. The code then becomes identical for everyone. Run `git pull`; their machine reproduces yours.

## See also

- [Environment variables and the `.env` file](environment-variables.md) — the mechanism that makes the same code run against three different filesystems.
- [Git and GitHub for research projects](git-and-github.md) — the version-control workflow that ties the local clone to the remote repo.
- [About AGENTS.md](agents-md.md) — what to put in the `AGENTS.md` at your repo root.
- [Jenny Bryan, *Naming Things*](https://speakerdeck.com/jennybc/how-to-name-files) — the canonical reference for file naming.
- [Jenny Bryan, *What They Forgot to Teach You About R*](https://rstats.wtf/) — broader project-organization wisdom for R users.
