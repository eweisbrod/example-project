---
title: SAS macros
parent: Topics
nav_order: 99
---

# SAS macros example: `MACROS.sas`

This folder ([browse on GitHub](https://github.com/eweisbrod/example-project/tree/main/sas-example)) mirrors a working SAS macro file (`MACROS.sas`) used in a real research pipeline, kept here as a teaching reference. The companion [`project-template`](https://github.com/eweisbrod/project-template) repo does not currently ship SAS scripts; if you want to apply the same `.env` / env-var pattern in a SAS pipeline of your own, this is a starting point you can copy.

## What's in here

- **`%load_env`** — a small SAS macro that parses a `.env` file (KEY=VALUE per line) and sets each entry as a global SAS macro variable. After `%load_env;` you can write `libname raw "&RAW_DATA_DIR";` and the path resolves from your `.env`. SAS doesn't ship a community dotenv package, so this fills the gap.
- **`%tddays`** — build a trading-day window relative to an event date using a CRSP trading-day calendar.
- **`%tdmins`** — same idea but at the minute granularity, for intraday work.
- **`%winsor`** — winsorize variables at user-supplied percentiles (e.g., 1%/99%).
- **`%ff12` / `%ff49`** — apply Fama-French 12-industry / 49-industry classifications from a SIC code (originally from <https://github.com/JoostImpink/fama-french-industry>).
- **`%iclink`** — WRDS's standard CRSP-IBES linking macro, lightly wrapped so it auto-points at WRDS libraries when you sign on.

## How to use

Copy `MACROS.sas` to your project's `src/` folder, then at the top of each SAS script:

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

`%load_env` reads `.env` from one directory above the executing `.sas` file (same convention as `dotenv` in R/Python — repo root, parallel to `src/`). Pass `%load_env(file=...)` to override.

### How `%load_env` finds the script (the two-way fallback)

SAS exposes the running script's path via two different mechanisms, each of which is only populated in *one* invocation mode:

| Source | Populated when |
|---|---|
| `getoption(sysin)` | Batch mode (`sas -SYSIN file.sas`, what `batch_run_sas` does) |
| `sysget(SAS_EXECFILEPATH)` | Interactive Submit (Enhanced Editor, Enterprise Guide) |

So both the bootstrap snippet above *and* `%load_env` itself try `SYSIN` first and fall back to `SAS_EXECFILEPATH`. The order matters: when SAS_EXECFILEPATH isn't defined, `sysget` prints a noisy WARNING that bumps SAS's exit code to 1 and shows up in every batch log. Checking SYSIN first avoids triggering that warning in the common batch case.

Once a path is in hand, `%load_env` strips the filename to get `src/`, then strips `src/` to get the repo root, then appends `.env`. (It does this with `findc(...,b)` + `substr` rather than `\..\..\` so it doesn't depend on the OS normalizing `path/file.sas/../../.env` correctly.)

The macro reads the file via `data _null_; infile; input;` and pushes each `KEY=VALUE` row to a global macro variable with `call symputx(key, val, "G")`. Compared to `filename`+`fopen`+`fread`, the data step gives you SAS's normal log diagnostics for free if anything goes wrong.

### Wrapping WRDS downloads with caching (`%maybe_download`)

A common pattern is "pull this dataset from WRDS the first time, but cache the local `.sas7bdat` and skip the download on re-runs." Once `MACROS.sas` is loaded and you've signed on to WRDS, define a tiny helper:

```sas
%macro maybe_download(target=, src=);
  %if not %sysfunc(exist(&target)) %then %do;
    rsubmit;
    proc download data=&src out=&target; run;
    endrsubmit;
  %end;
  %else %put NOTE: &target exists -- skipping download.;
%mend;

%maybe_download(target=raw.surpsum_07182025, src=ibes.surpsum);
%maybe_download(target=raw.statsum_epsus_07182025, src=ibes.statsum_epsus);
* ... etc;
```

Pair this with a *conditional* `signon`/`signoff` so you don't get a credential prompt on runs where every file is already cached:

```sas
%let need_wrds = 0;
%macro check_need(target=);
  %if not %sysfunc(exist(&target)) %then %let need_wrds = 1;
%mend;
%check_need(target=raw.surpsum_07182025);
%check_need(target=raw.statsum_epsus_07182025);
* ...one %check_need per cached target...;

%if &need_wrds = 1 %then %do;
  options comamid=TCP remote=WRDS;
  signon username=_prompt_;
%end;

* ... %maybe_download(...) calls here ... ;

%macro maybe_signoff;
  %if &need_wrds = 1 %then %do;
    signoff;
  %end;
%mend;
%maybe_signoff;
```

(Why is `signoff` wrapped in its own macro instead of being a bare `%if`? See the open-code-`%if` gotcha below.)

### Common SAS-batch gotchas

These bit me hard while building the pipeline, and aren't well-documented elsewhere:

- **Embedded `;` inside `* ... ;` comments terminate the comment early.** `*Decide whether downloads are needed; only signon if so;` parses as `*Decide whether downloads are needed;` (valid comment) followed by `only signon if so;` (treated as code, throws `ERROR 180-322: Statement is not valid`). Fix: use `--`, `:`, or `,` instead of `;` inside such comments, or switch to `/* ... */` block comments. The same trap affects `%put` strings — `%put NOTE: &target exists; skipping download.;` ends at the first `;`.

- **Open-code `%if` blocks have a nesting limit** (per SAS 9.4M5+). Calling a macro that internally has `%if` from within an open-code `%if/%then/%do; ... %end;` block (or just calling several macros in a row whose expansions contain `%if`) can cause a later open-code `%if` to fire `ERROR: Nesting of %IF statements in open code is not supported. %IF ignored.` — and the ignored `%if` then runs its body unconditionally. Fix: never put `%if` in open code that the script reaches *after* a chain of macro invocations. Wrap each open-code conditional in its own `%macro`/`%mend` (e.g. `%maybe_signoff` above), so the `%if` is inside a macro, not in open code.

- **Anything inside an `rsubmit` block runs on the WRDS server, not locally.** `%sysfunc(exist(raw.X))` inside `rsubmit` checks for `raw.X` on the WRDS-side libname stack — not your local libname. Existence checks for cached local files must be done *outside* the rsubmit/endrsubmit pair.

## Pointing SAS WORK at a different drive (`SAS_WORK_DIR`)

By default SAS uses `%TEMP%\SAS Temporary Files` for its WORK library — typically the OS drive (C: on Windows). On a heavy pipeline (large CSV imports, big SQL joins, multi-million-row intermediate datasets) the WORK library can balloon into tens of GB. If your OS drive is small or near-full, SAS will error out partway through with messages like:

```
ERROR: Insufficient space in file WORK.QUARTERLY_2015.DATA.
ERROR: File WORK.QUARTERLY_2015.DATA is damaged. I/O processing did not complete.
```

`project-template`'s `batch_run_sas()` (in both `utils.R` and `utils.py`) reads an optional `SAS_WORK_DIR` environment variable and, when set, passes `-WORK <path>` to SAS so the WORK library lands wherever you tell it. To enable it, add a line to your `.env`:

```
SAS_WORK_DIR=D:/sas-work
```

(Pick any local-fast-disk folder with ample free space — local SSD, not a network mount.) The folder is created automatically on first run.

If `SAS_WORK_DIR` is unset or empty, `batch_run_sas` does not pass `-WORK` and SAS falls back to its default. So you only need to set this if you actually hit the "Insufficient space" failure mode; coauthors with plenty of OS-drive space can leave it alone.

## Why this lives in `example-project` rather than a template

The hub README treats `example-project` as the home for teaching artifacts that don't fit cleanly into the language-specific template repos. SAS isn't part of `project-template`'s pipeline, so adding `MACROS.sas` to that repo would imply more SAS support than it actually provides. Keeping it here means `project-template` stays focused on the language combos it actually supports, while readers who want SAS still have a copy-pasteable starting point.

For more on the `.env` convention this macro file is built around, see the [hub README](../README.md) and the [project-template](https://github.com/eweisbrod/project-template) repo's setup documentation.
