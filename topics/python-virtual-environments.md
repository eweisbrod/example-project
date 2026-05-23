---
title: Python virtual environments
parent: In-depth topics
nav_order: 4
---

# Python virtual environments with `venv` and `uv`

This chapter explains what a Python virtual environment is, why a research project needs one, and why the templates standardize on `uv` for managing Python interpreters and packages — instead of any of the half-dozen older tools that solve overlapping pieces of the same problem.

<details open markdown="block">
<summary>On this page</summary>

1. TOC
{:toc}

</details>

## How Python's tooling differs from R, Stata, and SAS

The reason virtual environments feel like a hurdle to Python newcomers is that Python's relationship with its tooling is unlike what you're used to in the other languages researchers use:

- **R.** You install R (the language) and RStudio (the IDE) as two separate things, but R disappears into the background once RStudio is set up. Packages install globally via `install.packages()` and live in a user-writable directory by default. You rarely think about "which R am I running" because RStudio handles it.
- **Stata** and **SAS.** Even more bundled — you install one thing, and the language, the editor, and the package manager are rolled together. There's no "where's the Stata interpreter" question because Stata *is* the thing you opened.
- **Python.** The language and the editor are genuinely separate, and you assemble them yourself. The IDE (VS Code, Cursor, Positron, PyCharm) is just an editor — it doesn't *run* Python; it shells out to whichever Python interpreter you point it at. Choosing which Python and where it lives is your job. (See [Setting up your IDE](setting-up-your-ide.md) for the editor side of the picture; the rest of this chapter is the Python-runtime side.)

Adding to the confusion, "install Python" doesn't have one obvious answer. You could:

- Download the installer from [python.org](https://www.python.org/).
- Install [Anaconda](https://www.anaconda.com/) or Miniconda — a data-science bundle with its own package manager and its own non-PyPI package set.
- Let VS Code's Python extension prompt you to install one.
- Let `uv` download and manage Python interpreters for you on demand.
- Get one via Homebrew (macOS) or your system package manager (Linux).

All of these install a Python; some install several at once. New users routinely end up with three or four Python interpreters on the same machine and no idea which one their script is actually running against. The point of this chapter is to give you one clear path — install `uv`, let it handle everything else — and to explain the underlying concepts (interpreters, virtual environments, lockfiles) so the choice is informed rather than ritualistic.

## What's a virtual environment?

A Python virtual environment is an isolated folder containing its own Python interpreter and its own copy of any packages you install. Two projects with different virtual environments can use completely different package versions without interfering with each other. The same project on two different machines can recreate the same environment from a lockfile, so coauthors and replicators see identical behavior.

The R analog is **`renv`** — same job for R projects, captures the exact set of installed package versions per project.

The contrast that makes virtual environments necessary: by default `pip install pandas` installs into the system-wide Python, where every *program* on the machine sees it — including system utilities and other applications that use Python internally for things that have nothing to do with data science (OS package managers, GUI apps, build tools, etc.). Two projects that need different `pandas` versions can't coexist without one environment per project, and a careless global install can break an unrelated tool you didn't know was Python-based.

## Why a research project needs one

Concrete reasons an environment per project matters:

- **You may not have permission to install packages system-wide.** On many university-managed machines, the system Python is locked down — `pip install pandas` fails with a permissions error because you can't write to the system `site-packages` directory without IT involvement. A virtual environment is a per-user folder you own, so you can install whatever you want into it without admin rights or a support ticket. (For the same reason, the `uv` installer is designed to land in your user directory rather than a system location — see [Installing uv](#installing-uv) below.)
- **A new project breaks an old one.** Project A used `pandas==1.5` for two years. You start project B and `pip install pandas` upgrades to 3.0 globally. Running project A's pipeline now produces subtly different numbers because the pandas API changed. With per-project environments, A still sees 1.5 while B sees 3.0.
- **A reviewer can't reproduce your results.** You ran your analysis with `numpy==1.24.3`. A reviewer installs numpy fresh in 2027 and gets `numpy==2.5`. Their replication of your numbers fails for reasons neither of you understands. A committed lockfile makes the exact versions explicit and reproducible.
- **Cross-machine drift between coauthors.** You and your coauthor both "have pandas installed" but actually have different versions, and the same script produces different output. Per-project environments populated from the lockfile make this impossible.

## The Python tool landscape (and why uv)

For most of Python's history, virtual environments and packages have required juggling several separate tools:

| Tool | What it does | Replaces |
|---|---|---|
| **`venv`** (stdlib) | Creates a virtual environment | — |
| **`pip`** | Installs packages into the active environment | — |
| **`pip-tools`** | Adds lockfile support on top of pip (`pip-compile` → pinned `requirements.txt`) | — |
| **`pyenv`** | Manages multiple Python interpreter versions on one machine | — |
| **`pipx`** | Installs Python command-line tools globally without polluting the system environment | — |
| **`poetry`** | Combines environments, dependency resolution, and locking with its own `pyproject.toml` | venv + pip + pip-tools |
| **`conda`** / **`mamba`** | Anaconda's environment + package manager, with its own non-PyPI package set | venv + pip (but separate ecosystem) |
| **`uv`** | All of the above | venv + pip + pip-tools + pyenv + pipx |

The templates standardize on **`uv`** because it replaces nearly all of the older tools with one fast binary:

- Creates and manages virtual environments (replaces `venv` / `virtualenv`).
- Installs packages and resolves dependencies (replaces `pip` / `pip-tools`).
- Manages Python interpreter versions (replaces `pyenv`).
- Installs CLI tools (replaces `pipx`).
- Reads and writes the standard `pyproject.toml` plus a `uv.lock` lockfile (no proprietary format).
- ~10–100× faster than the older tools — Rust-based, parallel installs.

[Astral](https://astral.sh/) (the company behind `uv` and the makers of the [Ruff](https://docs.astral.sh/ruff/) linter) released `uv` in early 2024 and it's quickly become the modern standard. If you're starting a Python project now, `uv` is the cleanest pick.

## Installing uv

One-line install per the [official instructions](https://docs.astral.sh/uv/getting-started/installation/):

- **macOS / Linux:** `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **Windows (PowerShell):** `powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"`

After install, `uv --version` should print a version number. `uv` lives in your user directory; no admin rights needed.

You don't need to install Python separately — `uv` will download and manage Python interpreters for you on demand. `uv run` against a `pyproject.toml` that requires Python 3.12 will fetch a 3.12 interpreter automatically if you don't already have one.

## The `pyproject.toml` + `uv.lock` model

A `uv`-managed Python project lives around two files at the repo root:

- **`pyproject.toml`** — the project's *declared* dependencies, Python version constraints, and package metadata. You edit this directly or via `uv add`. Committed to git.
- **`uv.lock`** — the exact *resolved* package versions (including transitive dependencies) for everything in `pyproject.toml`. Generated by `uv`. Committed to git so coauthors and replicators get the same versions byte-for-byte.

A minimal `pyproject.toml` for a research project:

```toml
[project]
name = "your-project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "polars>=1.0",
    "duckdb>=1.0",
    "pyfixest",
    "great-tables",
    "keyring",
    "python-dotenv",
]
```

The companion `uv.lock` is generated automatically the first time you run `uv sync` or `uv run`. Don't edit it by hand — let `uv` regenerate it.

## Commands you'll actually use

Five commands cover ~95% of day-to-day work:

- **`uv sync`** — install everything in `pyproject.toml` into the project's venv (creating the venv if it doesn't exist), respecting `uv.lock`. Run this once after cloning the repo and any time `pyproject.toml` changes.
- **`uv run <command>`** — run a command inside the project's venv. `uv run python script.py`, `uv run src/001-download-data.py`, `uv run pytest`. `uv` auto-syncs first if needed, so this is usually all you have to type.
- **`uv add <package>`** — add a package to `pyproject.toml`, install it, and update `uv.lock` in one step. e.g. `uv add polars`.
- **`uv remove <package>`** — opposite of `add`.
- **`uv lock --upgrade`** — re-resolve everything to current versions and update the lockfile. Use sparingly; review the lockfile diff before committing.

You generally don't need to "activate" the environment the way you would with `source venv/bin/activate`. `uv run` handles activation transparently for that one command.

## How the templates use uv

The polyglot [`project-template`](https://github.com/eweisbrod/project-template) ships with a `pyproject.toml` and `uv.lock` at the repo root. The first time you run a Python pipeline script — e.g. `uv run src/001-download-data.py` — the template's `project_setup()` helper auto-runs, walks you through configuring `.env`, storing WRDS credentials in `keyring`, installing any missing dependencies, and verifying everything is wired up.

After that, every Python pipeline step is invoked through `uv run`:

```bash
uv run src/001-download-data.py
uv run src/002-transform-data.py
# ... etc
```

Or via the orchestrator:

```bash
uv run src/run-all.py
```

The `batch_run()` helper in `utils.py` internally invokes Python through a subprocess that respects the `uv`-managed venv, so per-script logs work the same way as R's `R CMD BATCH` flow does. See [JAR data policy](../pages/jar-data-policy.md) for what those logs are for.

## IDE integration

VS Code-family editors and PyCharm need to be told which Python interpreter to use for a project. Point them at the venv `uv` created (typically `.venv/bin/python` on macOS / Linux or `.venv/Scripts/python.exe` on Windows):

- **VS Code / Cursor / Positron:** click the Python interpreter indicator in the bottom-right status bar → "Enter interpreter path" → pick `.venv/bin/python` (or its Windows equivalent). The setting `python.defaultInterpreterPath` in `.vscode/settings.json` makes this stick across collaborators when committed.
- **PyCharm:** *Settings → Project → Python Interpreter → Add Local Interpreter → Existing → point at `.venv/bin/python`*.

Once the interpreter is set, the editor's IntelliSense / autocomplete, debugger, and integrated terminal all use the project's venv automatically.

See [Setting up your IDE](setting-up-your-ide.md) for the broader editor setup story this fits into.

## Common gotchas

- **Running plain `python` instead of `uv run python`.** Plain `python` uses your system interpreter (or whatever venv happens to be activated in that shell), not the project's venv. Symptoms: missing packages, wrong package versions, scripts that work for you but fail for a coauthor. Always prefix research-project commands with `uv run`.
- **Forgetting to commit `uv.lock`.** Without it, a coauthor doing `uv sync` gets the latest versions of everything matching your `pyproject.toml` constraints — which may differ from yours. The lockfile is the reproducibility artifact; commit it.
- **`uv` installed but not on `PATH`.** After install, you may need to restart your shell (or run the printed `export PATH=...` line) for the `uv` command to be found.
- **Editor still using the wrong interpreter.** If your editor's IntelliSense or test runner is hitting the global Python instead of the project venv, the interpreter setting is wrong. Reset it via the bottom-right status bar (VS Code-family) or PyCharm's interpreter settings, then restart the editor.
- **Mixing `uv` and `pip` in the same project.** Don't `pip install` into a `uv`-managed venv — the lockfile and `pyproject.toml` won't know about it, and the install vanishes the next time someone runs `uv sync`. Always use `uv add` for new dependencies; if you really need `pip`'s interface, use `uv pip install` which routes through `uv`.
- **`.venv/` accidentally committed.** Gitignore it. The lockfile + `pyproject.toml` are all someone needs to recreate the venv from scratch; the venv itself is large, machine-specific, and regenerable.

## See also

- [`uv` documentation](https://docs.astral.sh/uv/) — the canonical reference.
- [Astral's announcement post for uv](https://astral.sh/blog/uv) — the original motivation and tour of features.
- [PEP 621](https://peps.python.org/pep-0621/) — the Python standard that defines `[project]` in `pyproject.toml`.
- [Setting up your IDE](setting-up-your-ide.md) — broader editor setup, including the Python interpreter selection step referenced above.
- [Project structure for research](project-structure.md) — where the venv and `pyproject.toml` sit in the broader repo layout.
- [Environment variables and the `.env` file](environment-variables.md) — the `.env` mechanism the templates' Python code reads alongside the venv.
