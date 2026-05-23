---
title: Setting up your IDE
parent: In-depth topics
nav_order: 3
---

# Setting up your IDE

An integrated development environment (IDE) is the editor you'll spend most of your research-coding hours in. Picking one and configuring it well is a small upfront investment with significant ongoing payoff — fewer broken filesystems, fewer "where am I?" moments, fewer mistakes that only surface when you run a script end-to-end. This chapter covers what an IDE is, why a research project benefits from one over plainer alternatives (and over Jupyter notebooks), the project-folder mental model modern IDEs share, and per-editor setup notes for **RStudio and the VS Code family** — the editors most empirical researchers reach for.

<details open markdown="block">
<summary>On this page</summary>

1. TOC
{:toc}

</details>

## What is an IDE?

An IDE is a code editor that bundles, into one window, the tools you'd otherwise reach for separately: a file browser, a terminal, a version-control panel, a language interpreter (the R or Python console), a debugger, code completion, linting, and a syntax-aware text editor. The distinction from a "plain" editor like Notepad or Vim is breadth — an IDE knows about your language and your project's files, not just the bytes of the file you're editing.

Popular IDEs you'll encounter in academic and industry coding:

- **[RStudio](https://posit.co/download/rstudio-desktop/)** — by Posit (formerly RStudio Inc.). The default R-user IDE. Has Python support too but is best in class for R.
- **[VS Code](https://code.visualstudio.com/)** — by Microsoft. The most popular general-purpose editor in the world. Polyglot — works for R, Python, Stata (via extensions), SAS, LaTeX, everything. Free.
- **[Cursor](https://www.cursor.com/)** — a fork of VS Code with AI-first features built in (Cursor Agent, Tab completion, inline edits). Same UX as VS Code; adds Anthropic / OpenAI integration.
- **[Positron](https://positron.posit.co/)** — Posit's next-generation data-science IDE, also a VS Code fork. Built specifically for R and Python with an RStudio-style panel layout (console, Plots, Environment) on top of a VS Code core. Worth watching if you split your time between R and Python.
- **[PyCharm](https://www.jetbrains.com/pycharm/)** — by JetBrains. Heavyweight, Python-specific. Free Community edition; Pro is paid (free for academic use via JetBrains' education program).
- **[Spyder](https://www.spyder-ide.org/)** — open-source Python IDE shipped with Anaconda. MATLAB-like layout. Less common in business-school empirical work.

Among empirical researchers in business schools, the realistic picks are **RStudio** (for R-heavy work) and **VS Code / Cursor / Positron** (for polyglot or Python-heavy work). Stata users mostly use Stata's own IDE, which already does most of what this chapter describes.

## Why use an IDE — and why not a notebook

Plain text editors (Notepad, Sublime Text, Vim) work for editing code, but they leave the plumbing to you: switching to a separate terminal to run a script, manually tracking the working directory, no integrated debugger, no Git pane. The friction is small for each step but compounds — you end up skipping things that ought to be habits.

A more pointed contrast for research code is **Jupyter notebooks**. Notebooks are fine for exploratory scratchwork; for the reproducible code that ends up in a paper's replication package, they have several specific problems that an IDE-driven script workflow avoids:

- **Out-of-order execution.** A notebook's cells can be run in any order, any number of times, with state from anywhere in the notebook. The saved outputs reflect *whatever you last ran*, not necessarily the result of running cell 1 → cell N top-to-bottom. A reviewer cannot trust the displayed output without re-running the whole notebook themselves.
- **Hidden state.** Variables defined in a cell you later deleted are still in memory until you restart the kernel. The notebook on disk and the live Python process disagree, and you only find out when something fails for reasons you can't reproduce.
- **Diffs are JSON.** Notebooks are stored as JSON blobs that include cell outputs, execution counts, and metadata alongside the code. `git diff` on a `.ipynb` is unreadable. Tools like `nbdime` help, but it's strictly more friction than diffing a `.py` file.
- **Mixed code and output bloats the file.** A notebook with a large embedded matplotlib figure is megabytes; the equivalent script with a separate output file is kilobytes. Repos with checked-in notebooks balloon quickly.
- **The cell abstraction discourages modular code.** Cells reward small inline snippets; they make it slightly harder to define functions, write tests, or refactor across cells. For exploratory work that's fine; for code that has to run end-to-end without interactive intervention, scripts win.

The IDE alternative — write `.R` / `.py` / `.do` / `.sas` scripts in the editor, run them through `Rscript` / `uv run` / `stata -b` / `sas -SYSIN` (or through the templates' `batch_run()` for a JAR-style log) — preserves the strengths of notebooks (interactive REPL, plot pane) while shedding the reproducibility weaknesses. The IDE's console and plot pane give you the interactive experience; the script-on-disk gives you the reproducible artifact.

Notebooks aren't useless. They're great for prototyping and teaching. But the final code that runs your pipeline shouldn't be a notebook.

## How an IDE understands "your project"

Modern IDEs are organized around the assumption that work happens inside one folder, and that folder is the project. When you open a folder in RStudio, VS Code, Cursor, or Positron, the editor:

- **Sets the working directory** to that folder. Relative paths in scripts resolve against it — `source("src/utils.R")` works without `setwd()`.
- **Shows the folder's contents** in a file explorer in the sidebar. Other folders on your computer aren't visible unless you explicitly open them.
- **Looks at `.git/`** (if any) and wires up a source-control panel for that repo. Commits, push/pull, diff, branch — all without leaving the editor.
- **Loads editor-specific settings** the folder ships with (RStudio's `.Rproj`, VS Code's `.vscode/settings.json`) so the experience is consistent across collaborators.

This is the direct payoff for the layout described in [Project structure for research](project-structure.md). When that chapter says "the project root is the folder you cloned," it means the folder you'll open in your IDE — they're the same folder. The IDE's mental model and the on-disk project structure reinforce each other: one folder, one repo, one project, one working directory.

A practical consequence: **open the project root in your IDE, not a subfolder.** If you open `src/`, the IDE will treat `src/` as the project, set the working directory there, and relative paths like `../.env` or `RAW_DATA_DIR` lookups will resolve in surprising ways. Always *File → Open Folder* on the repo root.

## Source control inside the IDE

Every IDE in the list above ships with a Git integration that handles the everyday commit/push/pull workflow without dropping to a terminal:

- **RStudio**: the **Git** tab in the top-right pane. Modified files appear with checkboxes; *Commit* opens a dialog with a side-by-side diff and a commit-message field; *Push* / *Pull* buttons sync with GitHub. Branch operations via the branch dropdown.
- **VS Code / Cursor / Positron**: the **Source Control** tab in the left sidebar (the branching icon, or `Ctrl+Shift+G`). Same surface area — modified files with stage `+` buttons, commit-message box, sync via the cloud icon, branch picker in the status bar.

For everyday commit/push/pull, these panels are more convenient than the terminal. For branching, merging, conflict resolution, or anything weirder, the terminal is usually faster. Most people end up using both — the IDE pane for routine work, the terminal for everything else. See [Git and GitHub for research projects](git-and-github.md) for the underlying commands these panels wrap.

## RStudio specifics

When you click *File → New Project → Existing Directory* on a folder, RStudio creates a small `<project-name>.Rproj` file at the folder's root and treats it as an RStudio **Project**. Opening the `.Rproj` file (or *File → Open Project*) starts a fresh RStudio session anchored at that folder:

- Working directory set to the project root.
- Files / Plots / Environment panes scoped to that project.
- Git pane wired up to the `.git/` repo at the root.
- Panel layout and editor state remembered per-project.

The `.Rproj` file itself is small (a few key-value lines). **Commit it.** Coauthors who clone the repo and double-click the `.Rproj` get the same project setup for free.

`.Rproj.user/` is a different story — it's the per-machine session state (panel layout, file history, source cache). Gitignore it. The templates' `.gitignore` already does.

One more setting worth fixing the first time you install RStudio: turn off "Restore .RData on startup" and "Save workspace to .RData on exit" under *Tools → Global Options → General*. The default behavior loads in-memory variables from your last session, which is the easiest way to have variables in scope that aren't defined anywhere in your code. Bad for reproducibility. The "Never" / unchecked settings force you to re-run scripts to repopulate state, which is what you want.

## VS Code, Cursor, and Positron specifics

These three share a codebase (Cursor and Positron are VS Code forks), so their workflow is nearly identical. Opening a folder is *File → Open Folder…* — there's no project file required; the folder itself is the project.

Project-level settings live in a `.vscode/` folder at the project root:

- **`.vscode/settings.json`** — workspace-specific editor settings (tab width, default formatter, R/Python interpreter paths). Overrides your global user settings just for this project.
- **`.vscode/extensions.json`** — recommended extensions for the project. When a collaborator opens the folder, VS Code prompts them to install anything in this list they don't already have. Good for ensuring everyone has the R extension, Python extension, LaTeX Workshop, etc.
- **`.vscode/launch.json`** — debugger configurations, if you use the integrated debugger.

**Commit `.vscode/settings.json` and `.vscode/extensions.json`** when they hold conventions that should be shared. Skip the rest (per-user breakpoints, local state).

For R-in-VS Code, install the [REditorSupport R extension](https://marketplace.visualstudio.com/items?itemName=REditorSupport.r). For Python, install Microsoft's [official Python extension](https://marketplace.visualstudio.com/items?itemName=ms-python.python). For LaTeX, install [LaTeX Workshop](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop). Cursor and Positron ship most of these pre-wired.

## Ligature fonts

A small but high-quality-of-life upgrade: install a programming font that supports **ligatures** — visual glyphs that render common multi-character operators as a single combined symbol. `!=` displays as ≠, `->` as →, `>=` as ≥, etc. The underlying text on disk is unchanged; only the rendering changes.

Popular choices, all free:

- **[Fira Code](https://github.com/tonsky/FiraCode)** — the original ligature font, widely adopted.
- **[JetBrains Mono](https://www.jetbrains.com/mono/)** — JetBrains' open-source ligature font. Designed for long reading sessions.
- **[Cascadia Code](https://github.com/microsoft/cascadia-code)** — Microsoft's, ships with Windows 11. Both regular and ligature variants.

Install the font system-wide, then set it as your editor's default:

- **RStudio**: *Tools → Global Options → Appearance → Editor font*.
- **VS Code-family**: set `editor.fontFamily` in `settings.json` to the font name, and `editor.fontLigatures: true`.

## AI assistant integration

If you use an AI coding assistant — GitHub Copilot, Cursor's built-in agent, Claude Code, etc. — they all read [`AGENTS.md`](agents-md.md) (and sometimes `CLAUDE.md`) from the project root to understand your project. Once those files exist, the AI has context without you re-explaining things every session.

The IDE-side picture:

- **GitHub Copilot** works in both RStudio (built-in option in recent versions; see *Tools → Global Options → Copilot*) and VS Code (the official Copilot extension). Free monthly token budget for students and academics via [GitHub Education](https://education.github.com/benefits).
- **Cursor** has AI baked into the editor — Tab completion, inline edits, an Agent that can make multi-file changes. The best AI-first experience among VS Code-family editors. Free tier exists; paid tier removes rate limits.
- **Claude Code** runs in a terminal but integrates with the editor through file watching and the [Claude Code VS Code extension](https://docs.anthropic.com/en/docs/claude-code/ide-integrations).
- **Positron** has its own AI integrations developing rapidly; check [Positron's docs](https://positron.posit.co/) for current support.

Whichever you pick, configure AGENTS.md once in your project root and the assistant will read it automatically.

## Common gotchas

- **Opening a subfolder instead of the project root.** If your IDE doesn't see `.git/`, `.env`, or your README, you probably opened `src/` instead of the repo root. *File → Open Folder* on the parent.
- **RStudio's "Restore .RData on startup."** Default off in recent versions, but if it's on, RStudio saves your in-memory variables to disk and re-loads them next session. Breaks reproducibility — you can have variables defined that aren't anywhere in your code. *Tools → Global Options → General* → uncheck both ".RData" boxes, set "Save workspace to .RData" to "Never."
- **Python interpreter not matching your `uv` environment.** If you're using `uv` for Python (recommended throughout the templates), point VS Code / Cursor / Positron's Python extension at the venv `uv` created. The bottom-right status bar shows the current interpreter; click to switch. (A planned *Python virtual environments with venv and uv* topic on this site will cover this in more detail.)
- **`.Rproj.user/` accidentally committed.** Session state, not portable. Gitignore it. The templates already do.
- **Terminal opens in the wrong directory.** Some IDEs default the integrated terminal to your home directory rather than the project root. Check the IDE's terminal settings — VS Code has `terminal.integrated.cwd`; RStudio's terminal honors the project root by default.

## See also

- [Project structure for research](project-structure.md) — what the project folder you open in your IDE actually contains.
- [Git and GitHub for research projects](git-and-github.md) — the underlying Git operations the source-control pane wraps.
- [Environment variables and the `.env` file](environment-variables.md) — the `.env` file the IDE's working-directory setting makes findable.
- [About AGENTS.md](agents-md.md) — the AI-assistant context file every IDE-integrated assistant reads from the project root.
- [Fira Code](https://github.com/tonsky/FiraCode), [JetBrains Mono](https://www.jetbrains.com/mono/), [Cascadia Code](https://github.com/microsoft/cascadia-code) — programming fonts with ligature support.
