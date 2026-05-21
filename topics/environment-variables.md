---
title: Environment variables and .env
parent: In-depth topics
nav_order: 5
---

# Environment variables and the `.env` file

Most research projects need a small amount of *configuration* —
values that depend on where the project is running rather than what
the project is trying to compute. The path to your raw data folder, 
the path to your output folder, etc. These
are not part of the analysis; they are part of the local *environment*.
This note explains how the templates in this hub keep configuration
out of the code using environment variables and a `.env` file, why
that matters, and a few practical gotchas.

<details open markdown="block">
<summary>On this page</summary>

1. TOC
{:toc}

</details>

## What is an environment variable?

An environment variable is a `KEY=VALUE` pair maintained by your
operating system and visible to every program your OS launches.
Programs read them by name. R reads `Sys.getenv("DATA_DIR")`,
Python reads `os.getenv("DATA_DIR")`, and below I discuss how these concepts can be extended to SAS and Stata. The variable
is the same in all four — it lives at the operating-system level,
and the programs are just asking the OS what its current value is.

When you open a terminal and type `set` (Windows CMD), `env` (Bash /
macOS), or `Get-ChildItem env:` (PowerShell), you'll see a long list
of variables your OS is already maintaining: `PATH`, `HOME`,
`USERNAME`, `TEMP`, and many others. You *could* add a project-
specific variable like `DATA_DIR` directly to that OS-level list —
and on some systems people do — but in practice that turns out to
be a bad fit for research projects. The next two sections explain
why, and what the templates do instead.

## Why use environment variables in a research project?

If you hardcode the path to your data in a script:

```r
data <- read_parquet("D:/Dropbox/my-project/data/regdata.parquet")
```

…then the script runs on *your* machine, and only your machine, and
only as long as that path doesn't change. The moment a coauthor
opens the same script, or you move the data to a different drive,
the script breaks.

If instead you read the path from an environment variable:

```r
data_dir <- Sys.getenv("DATA_DIR")
data <- read_parquet(glue("{data_dir}/regdata.parquet"))
```

…the script reads whatever `DATA_DIR` resolves to *on the machine
where it's currently running*. Different machine, different
`DATA_DIR`, same script — no edits needed.

This is one of the most important habits in a reproducible research
workflow: **separate code from configuration**. The code lives in git (version control),
the configuration lives outside git, and you don't have to edit code
to change configuration. This also makes code shareable between coauthors and clean for posting on academic journal websites without revealing your personal information.

## Project-level configuration via `.env`

The OS-level approach is fine for variables that really are global —
`PATH`, `HOME`, your default editor. Research projects don't fit
that mold. A typical empirical researcher has *several* active
projects at any one time, each with its own data folder, its own
output folder, sometimes its own sample window or feature flags.
If `DATA_DIR` lives at the OS level there is only one of it at any
moment, and you'd be editing your OS environment every time you
switched between projects. That's noisy, error-prone, and
impractical to share with a coauthor.

The convention the templates follow instead is a small text file
named `.env` at the *project root*. The file is just `KEY=VALUE`
lines, for example:

```
RAW_DATA_DIR=D:/Dropbox/my-project/data/raw
DATA_DIR=D:/Dropbox/my-project/data/derived
OUTPUT_DIR=output
```

Each of R, Python, Stata, and SAS has code provided that reads
this file at the start of a script and exposes its contents as if
they were OS-level environment variables (the section below covers
the specifics). The benefits over an OS-level setup:

- **One file per project.** Every project has its own `.env`, so
  `DATA_DIR` can take a different value in every project on the
  same machine — no manual switching, no global conflicts.
- **Project-level overrides win.** When a `.env` value coexists
  with an OS-level variable of the same name — a stale `DATA_DIR`
  left over from another project, say — the project's `.env` takes
  precedence, provided you call the loader correctly (in Python,
  `override=True`; see below). The OS keeps its global defaults
  and individual projects get the last word inside their own scope.
- **No admin rights needed.** Setting OS-level env vars on a
  managed university machine can require admin privileges; editing
  a text file in your own project folder never does.
- **A coauthor copies `.example-env`, edits the paths, runs.**
  Sharing OS-level configuration is impractical — everyone's
  environment is different. Sharing a project-level `.env`
  template is trivial.

The `.env` file is *just* a text file. There's no magic. You can
edit it in any text editor. The format is intentionally trivial so
that every language can read it.

## The three (sometimes more) env vars used in this template

The example pipeline reads three variables out of `.env`:

| Variable | What it points at |
|---|---|
| `RAW_DATA_DIR` | The folder holding raw data pulls (large, slow to refresh, treated as read-only inputs). |
| `DATA_DIR` | The folder holding derived datasets that the pipeline produces (`regdata.parquet`, `figure-data.parquet`, etc.). Safe to delete and regenerate. |
| `OUTPUT_DIR` | The folder holding final tables and figures (`.tex`, `.pdf`, `.png`, `.docx`, `.rtf`). |

A few optional variables are read when present:

| Variable | Purpose |
|---|---|
| `STATA_BIN` | Full path to the Stata executable, if `stata` isn't on your PATH. Read by `batch_run_stata()`. |
| `SAS_BIN` | Full path to the SAS executable, if `sas` isn't on your PATH. Read by `batch_run_sas()`. |
| `SAS_WORK_DIR` | Override for SAS's WORK library when the default `%TEMP%` location is on a too-small drive. |

The rule for what belongs here: **anything that varies by machine
or user**. The path to your data folder, the path to a Stata
executable, a per-machine memory budget. Anything that should be
the same for every collaborator and every future replicator — the
sample window, the winsorization percentile, the regression
specification — belongs in code, committed to git, not in `.env`.
The "Other uses" section near the end gives concrete examples on
both sides of that line.

## A worked example: two authors, three machines

Suppose you (Author 1) are collaborating with one coauthor (Author 2) on a paper. Between
the two of you, you use three machines, each of which has different
paths to the data:

**Author 1, laptop** — small SSD, Dropbox folder on `C:`:
```
RAW_DATA_DIR=C:/Dropbox/our-paper/data/raw
DATA_DIR=C:/Dropbox/our-paper/data/derived
OUTPUT_DIR=output
```

**Author 1, desktop** — large secondary drive, data on `D:`:
```
RAW_DATA_DIR=D:/Dropbox/our-paper/data/raw
DATA_DIR=D:/Dropbox/our-paper/data/derived
OUTPUT_DIR=output
```

**Author 2, MacBook** — macOS, no drive letters, Dropbox in `~`:
```
RAW_DATA_DIR=/Users/coauthor/Dropbox/our-paper/data/raw
DATA_DIR=/Users/coauthor/Dropbox/our-paper/data/derived
OUTPUT_DIR=output
```

Same code, three different `.env` files. Every author runs the
pipeline on their own machine, the scripts pick up the right paths
from `.env`, and no one ever has to edit a `read_parquet()` line.

This is also why **paths in `.env` use forward slashes even on
Windows**. R, Python, Stata, and SAS all accept `/` on Windows
without conversion, but interpreting `\` requires escaping (`\\`)
which is error-prone. The convention across the templates is
unconditional forward slashes; the scripts handle them correctly on
every OS.

## `.env` must be gitignored

`.env` is **never** committed to git. The templates' `.gitignore`
files all include `.env`. This is non-negotiable
for three reasons:

1. **`.env` is machine-specific.** If Author 1's `.env` got committed
   from the laptop, Author 2 would clone it and the paths would point
   at directories that don't exist on the Mac.
2. **`.env` is the natural place to accidentally put secrets.**
   Even though the templates teach you to keep credentials in the
   OS keyring (see below), some teammate at some point will paste a
   WRDS password into `.env` while debugging. Once committed, that
   password is in your git history forever, even after you delete
   it from the current file. Treat `.env` like a credentials file:
   never commit, never push, etc.
3. **`.env` is meant to be customized.** Each collaborator should
   have their own. Committing yours creates merge conflicts and
   confused expectations.

### What you DO commit: `.example-env`

To tell new contributors what variables they need to set, the
templates commit a sibling file called `.example-env`. Same `KEY=VALUE`
format, but with placeholder values:

```
RAW_DATA_DIR=D:/Dropbox/your-project-name/data/raw
DATA_DIR=D:/Dropbox/your-project-name/data/derived
OUTPUT_DIR=output
```

A new contributor copies `.example-env` to `.env`, fills in their
real paths, and is up and running.

(The name is `.example-env`, not `.env.example`. The reason is
collision safety: `.env*` glob patterns and casual `git rm .env*`
commands match `.env.example` and could accidentally delete or
re-add the real `.env`.)

## How each language reads `.env`

The mechanism is slightly different in each language, but the
result is the same: you call a function or `%include` a macro,
and after that your script can read any variable defined in `.env`.

### R

```r
library(dotenv)
load_dot_env(".env")
raw_data_dir <- Sys.getenv("RAW_DATA_DIR")
data_dir     <- Sys.getenv("DATA_DIR")
```

The `dotenv` package is available on CRAN. `load_dot_env(".env")` parses the
file and sets each KEY as a real OS-level environment variable for
the duration of the R session.

### Python

```python
from dotenv import load_dotenv
import os

load_dotenv(".env", override=True)
raw_data_dir = os.getenv("RAW_DATA_DIR")
data_dir     = os.getenv("DATA_DIR")
```

The `python-dotenv` package on PyPI. The `override=True` argument
matters: by default, `python-dotenv` does NOT override an existing
system-level environment variable with the same name. If you have
`DATA_DIR` set in your Windows User Environment Variables (for
example, because a previous project set it system-wide), Python
will silently use the system value and ignore your project's `.env`.
`override=True` makes the project's `.env` win, which is almost
always what you want for a reproducible project.

### Stata

Stata does not ship with a `.env` reader, so the templates use a
combination of two community packages to get the same behavior:

- **`projectpaths`** — a Stata package I wrote that records the
  on-disk location of each registered project, so a `.do` file can
  `cd` to its own project root before any other command runs.
  This matters here because `doenv` looks for `.env` in the
  current working directory; without `projectpaths`, you'd have to
  manually `cd` to the project root every time you launch Stata. This 
  package is also useful for any other commands that rely on setting Stata's
  current working directory to the corresponding project root for each user or machine.
- **`doenv`** by Vik Jam — parses a `.env` file and exposes each
  `KEY` as an `r()` result.

Install both once per Stata installation:

```stata
net install projectpaths, from("https://raw.githubusercontent.com/eweisbrod/projectpaths/main/src/") replace
net install doenv, from("https://github.com/vikjam/doenv/raw/master/")
```

Then register the project's location with `projectpaths` (once per
project, e.g.):

```stata
project_paths_list, add project(your-project-name) path("C:/_git/your-project-name")
```

After this one-time setup for each coauthor, every `.do` file in the project can open with the same
preamble:

```stata
project_paths_list, project(your-project-name) cd
doenv using ".env"
local raw_data_dir "`r(RAW_DATA_DIR)'"
local data_dir     "`r(DATA_DIR)'"
```

Note the slightly different idiom: Stata exposes the values as
`r()` results rather than as OS env vars, so you assign them to
local macros for use in your script.

### SAS

SAS does not ship a community dotenv package, so the
[`sas-example/MACROS.sas`](../sas-example/MACROS.sas) file in this
hub provides a `%load_env` macro that fills the gap.

Unlike R, Python, and Stata, SAS has no clean built-in for "where
am I running from" — and `%load_env` needs that, because it looks
for `.env` relative to the executing `.sas` file. The preamble
therefore resolves `&codepath` (the full path of the currently-
executing `.sas` file) before doing anything else, by reading
whichever of two SAS-provided values is populated:

- `SYSIN` — set automatically when SAS is launched in batch mode
  via `sas -SYSIN script.sas`.
- `SAS_EXECFILEPATH` — set automatically by Enhanced Editor and
  Enterprise Guide when you submit a script interactively.

Once `&codepath` is known, the preamble can `%include` the macros
file and call `%load_env`:

```sas
/* Resolve the running script's path. SYSIN is set in batch mode (sas -SYSIN);
   SAS_EXECFILEPATH is set by Enhanced Editor / Enterprise Guide interactively. */
%let codepath = %sysfunc(getoption(sysin));
%if %length(&codepath) = 0 %then %do;
    %let codepath = %sysfunc(sysget(SAS_EXECFILEPATH));
%end;
%include "&codepath\..\MACROS.sas";
%load_env;

libname raw  "&RAW_DATA_DIR";
libname data "&DATA_DIR";
```

After `%load_env;`, each `KEY` from `.env` is available as a global
SAS macro variable (`&RAW_DATA_DIR`, `&DATA_DIR`, etc.). By default,
the macro derives the path to `.env` from `&codepath` by stripping
the `.sas` filename and then stripping one more directory level —
with the conventional `src/foo.sas` layout, that lands on the repo
root. The macro doesn't check for the literal name `src/`; any
project where the `.sas` file lives one directory below `.env`
works. If the auto-derived path doesn't exist, `%load_env` errors
out clearly and tells you to pass an explicit path via
`%load_env(file=...)`.

See [`sas-example/README.md`](../sas-example/README.md) for the
fine print on how the SAS implementation handles batch vs.
interactive mode.

## Credentials do NOT go in `.env`

This is the rule that catches most people the first time they set
up an `.env` file. **`.env` is for non-secret configuration only.**
Things like paths, project names, feature flags. It is NOT for:

- WRDS usernames and passwords
- API keys
- Database connection strings that include passwords
- SSH private keys
- Anything else you would not want to accidentally email

The risk is the same as the gitignore risk above: even with `.env`
gitignored, secrets in plain text leak through too many side
channels. 

The templates handle credentials two different ways depending on
language:

- **R, Python**: the `keyring` package stores credentials in the
  OS-native credential store (Windows Credential Manager on
  Windows, Keychain on macOS, Secret Service on Linux). The
  templates store both the WRDS username and password under the
  service `"wrds"`, using the literal key names `"username"` and
  `"password"`, so R and Python read the same two entries. In R
  the setter is interactive — `key_set` prompts you to type the
  value at runtime, so no plaintext appears in your script:

  ```r
  keyring::key_set("wrds", "username")  # prompts; type your WRDS username
  keyring::key_set("wrds", "password")  # prompts; type your WRDS password
  ```

  Python's `keyring.set_password()` takes the value as an argument
  rather than prompting, so the interactive equivalent reads from
  `input` / `getpass`:

  ```python
  import keyring
  from getpass import getpass
  keyring.set_password("wrds", "username", input("WRDS username: "))
  keyring.set_password("wrds", "password", getpass("WRDS password: "))
  ```

  After that, scripts read on demand — `keyring::key_get("wrds",
  "username")` in R, `keyring.get_password("wrds", "username")` in
  Python — and the credentials never sit in a file; they live in
  the OS's encrypted credential vault. The templates'
  `project_setup()` (R) and `setup.py` (Python) walk through this
  prompt-and-store flow the first time you run the pipeline.
- **Alternate** (from WRDS Examples):
  The WRDS guidance is to use a `.pgpass` file in your home directory
  with mode 0600 file permissions, which the PostgreSQL client
  libraries read automatically. Same logical separation — secrets
  outside the project tree, project tree free of secrets.

A useful mental test: **if you would not want this value to appear
in a screenshot during a Zoom presentation, it does not belong in
`.env`.**

## Other uses of `.env` beyond paths

Paths and binary locations are the most common uses, but anything
else that legitimately varies *by machine or by user* is a good
fit too. A few examples:

- **Per-machine compute resources**: `MAX_RAM_GB=16`,
  `N_WORKERS=8`. Lets the same parallel-processing code run on a
  16 GB laptop and on a 256 GB server without manual tuning.
- **Non-standard service endpoints**, *only* if they actually vary.
  `WRDS_HOST=wrds-pgdata.wharton.upenn.edu` is the same for
  everyone and so is hardcoded in the templates; if you're hitting
  a custom mirror or a private host, that's a legitimate `.env` use.

### What does NOT belong in `.env`

The reverse matters just as much. Anything that is part of the
*analytical design* should NOT live in `.env`, because it should
be the same for every collaborator and every future replicator.
That includes:

- The project name, citation key, paper title.
- Sample window (e.g., `START_FYEAR=1970`, `END_FYEAR=2024`).
  These define your study's sample and have to be reproducible.
- Variable construction choices — winsorization percentile,
  scaling denominator, which sub-sample to exclude. These are
  analytical decisions.
- Regression specifications, fixed-effect choices, clustering.

All of those belong in code, committed to git, where they can be
versioned and reviewed. The dividing test:

> **If a future replicator running your code 
> needs a particular value to be a particular number to reproduce
> your tables, that value is part of the analysis — put it in
> code. If it's something they'd legitimately want to change to
> match their own machine or account, put it in `.env`.**

## Common gotchas

A handful of things that bite people the first time:

1. **Backslashes on Windows.** Use forward slashes (`/`) in `.env`
   regardless of OS. R, Python, Stata, and SAS all accept them on
   Windows; backslashes require escaping and create platform-
   specific paths that break on Mac and Linux.
2. **No `#` comments inside `.env`.** Strict `KEY=VALUE` only. Some
   dotenv libraries' `#`-comment parsing is finicky around values
   that contain `#` (e.g., a URL with a fragment); the templates'
   convention is to avoid them entirely and document what each
   variable means in this topic page or in a README instead. The
   `.example-env` files in the templates are also comment-free.
3. **Quotes around values.** Avoid them. `DATA_DIR=D:/foo/bar` not
   `DATA_DIR="D:/foo/bar"`. The dotenv libraries usually strip the
   quotes correctly, but not always, and it's easier to never
   introduce them.
4. **Trailing whitespace.** `DATA_DIR=D:/foo/bar ` (with a trailing
   space) silently sets `DATA_DIR` to a path that ends in a space.
   This breaks file reads in baffling ways. Use a text editor that
   shows whitespace if you keep seeing "file not found" on paths
   that look right.
5. **System-level env vars shadowing your project's `.env`.** In
   Python this is the `override=True` issue covered above. In R,
   `Sys.getenv()` returns whatever was set most recently in the
   session, so if you accidentally set `DATA_DIR` from another
   project earlier, it will leak. Restart R or `Sys.unsetenv()` if
   you're not getting the expected value.
6. **`.env` not found.** The template code generally looks for `.env` in the
   *current working directory*, which is assumed to be the project root directory, not the script's directory (e.g., src/). If the
   working directory is not the project- root, or more generally not where `.env` is stored, you may get the `.env` not found error. 

## How to debug when `.env` isn't loading

The symptom is usually a path-related error: "file not found,"
"directory does not exist," `Sys.getenv("DATA_DIR")` returning the
empty string. Three diagnostic steps in order:

1. **Print the loaded value.** Right after `load_dot_env(".env")`,
   add `print(Sys.getenv("DATA_DIR"))` (or the Python/Stata/SAS
   equivalent). If it's empty, the file wasn't loaded or the
   variable wasn't in it. If it's the wrong value, you have a
   shadowing problem (see gotcha #5).
2. **Check the working directory.** `getwd()` (R), `os.getcwd()`
   (Python), `pwd` (Stata) — confirm you're in the project root.
3. **Open `.env` in a hex-aware editor** if all else fails. Things
   like a BOM at the start of the file (some Windows editors add
   one), trailing CRLF vs LF line endings on Mac, or invisible
   trailing whitespace can all break parsing. VS Code's "Show
   Whitespace" toggle is the easiest way to see what's actually
   there.

## A note on R's `.Renviron`

R has long had its own version of project-level configuration via
a file called `.Renviron` (at the project root) or `~/.Renviron`
(at the user level). It does very similar work to `.env`: a file
of `KEY=VALUE` lines that R reads at startup and exposes through
`Sys.getenv()`. Earlier versions of these templates used
`.Renviron` for exactly that purpose.

The current templates standardize on `.env` plus the `dotenv`
package instead, for one reason: a project that mixes R, Python,
Stata, and SAS needs **one** configuration file that **all four**
languages can read. `.Renviron` is R-only; `.env` is universal.

## See also

- [`sas-example/README.md`](../sas-example/README.md) — the SAS
  `%load_env` macro and its batch-vs-interactive handling.
- The `project_setup()` function in each language's `utils.{R,py}`
  in the [`project-template`](https://github.com/eweisbrod/project-template)
  repo — walks new users through creating their first `.env`
  interactively.
- [`.example-env`](https://github.com/eweisbrod/project-template/blob/main/.example-env)
  in the polyglot template — the committed placeholder file.
