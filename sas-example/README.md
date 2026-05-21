---
title: SAS Examples
parent: Topics
nav_order: 99
---

# SAS-example Folder:

This folder ([browse on GitHub](https://github.com/eweisbrod/example-project/tree/main/sas-example)) holds three artifacts that together form a copy-pasteable starting point for projects that include SAS:

- **[`MACROS.sas`](MACROS.sas)** — the macro library (`%load_env`, `%tddays`, `%winsor`, `%ff12`/`%ff49`, `%iclink`, …). Full inventory at the end of this page.
- **[`002-merge-fdp-data.sas`](002-merge-fdp-data.sas)** — a real working SAS script using `MACROS.sas`. Copied verbatim from the [`consensus`](https://github.com/eweisbrod/consensus) repo (where it lives at [`src/002-merge-fdp-data.sas`](https://github.com/eweisbrod/consensus/blob/main/src/002-merge-fdp-data.sas)). Same license (CC-BY-4.0).
- **This `README.md`** — a step-by-step walkthrough of the conventions, anchored on a trimmed excerpt of `002-merge-fdp-data.sas`.

The companion [`project-template`](https://github.com/eweisbrod/project-template) repo does not ship SAS scripts, so these reference materials live here instead. For a complete real-world project using the conventions end-to-end across **R, Stata, and SAS**, see the [`consensus`](https://github.com/eweisbrod/consensus) repo — every SAS script there (`002`–`005`) follows the patterns described below; the rest of the pipeline (download, transform, analysis, figures) is in R and Stata.


## A complete example, annotated

The trimmed excerpt below keeps the scaffolding used for the `proc sql` steps that follow the preamble. The full ~820-line working script is sitting alongside this README at [`002-merge-fdp-data.sas`](002-merge-fdp-data.sas) — open it for the complete picture. The trimmed version below demonstrates every convention `MACROS.sas` is designed around: portable paths via `.env`, conditional WRDS signon, cached WRDS downloads, and clean exits.

```sas
/* 002-merge-fdp-data.sas (excerpt from the consensus repo)
 * Link master CCM observations to I/B/E/S forecasts. Downloads any
 * missing raw .sas7bdat files from WRDS; skips the download when a
 * cached file already exists on disk.
 */

/* Resolve the path to this script. SYSIN is set in batch mode
   (sas -SYSIN ..., what batch_run_sas does). SAS_EXECFILEPATH is
   set by Enhanced Editor / Enterprise Guide on interactive Submit. */
%let codepath = %sysfunc(getoption(sysin));
%if %length(&codepath) = 0 %then %do;
    %let codepath = %sysfunc(sysget(SAS_EXECFILEPATH));
%end;

%include "&codepath\..\MACROS.sas";
%load_env;

libname raw  "&RAW_DATA_DIR";
libname data "&DATA_DIR";

/* --- Conditional WRDS signon: only prompt for credentials if a
   download is actually needed. */
%let need_wrds = 0;
%macro check_need(target=);
  %if not %sysfunc(exist(&target)) %then %let need_wrds = 1;
%mend;
%check_need(target=raw.surpsum_07182025);
%check_need(target=raw.statsum_epsus_07182025);
* ... one %check_need per cached target ...;

%if &need_wrds = 1 %then %do;
  options comamid=TCP remote=WRDS;
  signon username=_prompt_;
%end;
%else %put NOTE: All WRDS-downloaded raw files already exist -- skipping signon.;

/* --- Cached downloads: re-runs reuse the local .sas7bdat. */
%macro maybe_download(target=, src=);
  %if not %sysfunc(exist(&target)) %then %do;
    rsubmit;
    proc download data=&src out=&target; run;
    endrsubmit;
  %end;
  %else %put NOTE: &target exists -- skipping download.;
%mend;

%maybe_download(target=raw.surpsum_07182025,       src=ibes.surpsum);
%maybe_download(target=raw.statsum_epsus_07182025, src=ibes.statsum_epsus);
* ... etc ...;

/* --- The analysis. proc sql joins / datasteps that link
   raw.master_ccm with the just-downloaded raw files and write
   to data.all_five1. (See the consensus repo for the full version.) */

/* --- Clean exit: signoff only if we signed on. The %if must be
   inside a macro, not in open code -- see Gotchas below. */
%macro maybe_signoff;
  %if &need_wrds = 1 %then %do;
    signoff;
  %end;
%mend;
%maybe_signoff;
```


### Step 1 — Resolve `&codepath`, `%include` macros, `%load_env`

The first three lines answer the question "where is this script running from?" — SAS has no clean built-in for it, but two SAS-provided values cover the two execution modes:

| Source | Populated when |
|---|---|
| `getoption(sysin)` | Batch mode (`sas -SYSIN file.sas`, what `batch_run_sas` does) |
| `sysget(SAS_EXECFILEPATH)` | Interactive Submit (Enhanced Editor, Enterprise Guide) |

The preamble tries SYSIN first because `sysget` on an undefined environment variable prints a noisy WARNING that bumps SAS's exit code to 1 and would otherwise show up in every batch log. Checking SYSIN first avoids triggering that warning in the common batch case.

Once `&codepath` is known, `%include "&codepath\..\MACROS.sas";` pulls in the macro library, and `%load_env;` parses `.env` and pushes every `KEY=VALUE` row into the SAS global macro namespace as `&KEY`. For the path-derivation rules (`%load_env` strips the filename + one more directory level), the `file=` override, and the broader `.env` convention, see [Environment variables and .env](../topics/environment-variables.md#sas).

### Step 2 — Libnames from `.env`

```sas
libname raw  "&RAW_DATA_DIR";
libname data "&DATA_DIR";
```

The point of `.env` is that the paths are *not* hardcoded in the script. The same script runs on every collaborator's machine; each has their own `.env` pointing at their own copy of the data. `RAW_DATA_DIR` is the folder of raw WRDS pulls (`.sas7bdat` files downloaded from WRDS); `DATA_DIR` is for derived datasets the script writes. See [the worked example](../topics/environment-variables.md#a-worked-example-two-authors-three-machines) for how this lets two coauthors with different filesystems run the same code.

### Step 3 — Conditional WRDS signon

The four-line `%check_need` pattern matters for replication runs. If every cached `.sas7bdat` already exists, `need_wrds` stays 0, the script never calls `signon`, and a reviewer can verify the analysis end-to-end without a WRDS account. Only when at least one file is missing does the script prompt for credentials. This is the SAS-side counterpart to the R/Python templates' `skip_if_exists` argument on `download_parquet()`.

### Step 4 — Cached downloads with `%maybe_download`

Each `proc download` is wrapped in an existence check. If `raw.surpsum_07182025` already exists locally, the macro prints a NOTE and skips. If not, `proc download` runs inside an `rsubmit` block (required — `proc download` is server-side only). A first run downloads everything once and writes to `RAW_DATA_DIR`; every subsequent run reuses the local copies. Deleting a single `.sas7bdat` triggers a re-download of just that file.

### Step 5 — The analysis

Below the download block in the real script sits the analytical body: `proc sql` joins linking `raw.master_ccm_*` to each forecast-data provider (I/B/E/S, FactSet, Zacks, Capital IQ, Bloomberg), datasteps that compute scaled surprises and coverage indicators, and a final write to `data.all_five1` (i.e. `DATA_DIR/all_five1.sas7bdat`). The shape is identical to what the R/Python templates' transform step does: read raw, derive, write to `DATA_DIR`. The language is SAS; the conventions are the same.

### Step 6 — Conditional signoff (and why it lives in a macro)

```sas
%macro maybe_signoff;
  %if &need_wrds = 1 %then %do;
    signoff;
  %end;
%mend;
%maybe_signoff;
```

The body could have been a plain `%if &need_wrds = 1 %then signoff;`, but SAS forbids `%if` in open code under certain nesting conditions (see [the open-code-`%if` gotcha below](#open-code-if)). Wrapping it in a tiny macro sidesteps the limit. Same trick applies to any `%if` that has to live outside a `%macro` definition in a script that earlier called macros containing `%if`.


## Running the script via `batch_run_sas()` for journal-quality logs

The patterns above produce data, but not yet a log. JAR (and similar code-sharing policies) expect a SAS-log-style record of every step the pipeline ran alongside the code itself — every statement echoed, every PROC's output interleaved, every NOTE / WARNING / ERROR, in plain text. The templates produce that log by invoking SAS in batch mode through `batch_run_sas()`, defined in `project-template/src/utils.R` (R) and `project-template/src/utils.py` (Python).

From an R `run-all.R`:

```r
source("src/utils.R")  # provides batch_run / batch_run_sas / batch_run_stata
batch_run_sas("src/002-merge-fdp-data.sas")
# -> writes log/002-merge-fdp-data-sas.log
```

`batch_run_sas()` internally:

1. **Locates the SAS binary.** Reads `SAS_BIN` from `.env` if set; otherwise searches common install paths (`C:/Program Files/SASHome/SASFoundation/*/sas.exe` and Unix equivalents) and then `PATH`.
2. **Overrides SAS WORK** if `SAS_WORK_DIR` is set in `.env` — see [SAS_WORK_DIR below](#pointing-sas-work-at-a-different-drive-sas_work_dir).
3. **Invokes SAS** in batch mode: `sas -SYSIN src/002-merge-fdp-data.sas -LOG log/002-merge-fdp-data-sas.log [-WORK <dir>]`.
4. **Captures the exit code** and surfaces a warning if it's non-zero.

The default log filename uses a `-sas.log` suffix so a hypothetical `4-analyze-data.do` (Stata) and `4-analyze-data.sas` running side-by-side don't collide on log filename. The `.log` file itself is the SAS-native log — a reviewer can grep it without running SAS.

A Python `run-all.py` calls the identically-named `batch_run_sas()` from `utils.py`; the contract is the same.


## Gotchas to keep in mind when writing SAS for `batch_run_sas`

A handful of SAS quirks that aren't well-documented elsewhere and that the example above is structured to work around:

- **Embedded `;` inside `* ... ;` comments terminate the comment early.** `*Decide whether downloads are needed; only signon if so;` parses as `*Decide whether downloads are needed;` (valid comment) followed by `only signon if so;` (treated as code, throws `ERROR 180-322: Statement is not valid`). Use `--`, `:`, or `,` instead of `;` inside such comments, or switch to `/* ... */` block comments. The same trap affects `%put` strings — `%put NOTE: &target exists; skipping download.;` ends at the first `;`. In batch mode you only see this failure in the `.log` after the run completes, so it's easy to ship a script that runs interactively but fails under `batch_run_sas`.

- <a name="open-code-if"></a>**Open-code `%if` blocks have a nesting limit** (per SAS 9.4M5+). Calling a macro that internally contains `%if` from within an open-code `%if/%then/%do; ... %end;` block — or just calling several macros in a row whose expansions contain `%if` — can cause a later open-code `%if` to fire `ERROR: Nesting of %IF statements in open code is not supported. %IF ignored.` And the ignored `%if` then runs its body unconditionally, silently. Fix: never put `%if` in open code that the script reaches *after* a chain of macro invocations. Wrap each open-code conditional in its own `%macro`/`%mend` (the `%maybe_signoff` pattern above), so the `%if` is inside a macro, not in open code.

- **Anything inside an `rsubmit` block runs on the WRDS server, not locally.** `%sysfunc(exist(raw.X))` *inside* `rsubmit` checks for `raw.X` on the WRDS-side libname stack, not your local libname. Existence checks for cached local files must be done *outside* the `rsubmit/endrsubmit` pair — which is why `%maybe_download` puts the `%if not exist` check around `rsubmit`, not inside it.


## Pointing SAS WORK at a different drive (`SAS_WORK_DIR`)

By default SAS uses `%TEMP%\SAS Temporary Files` for its WORK library — typically the OS drive (C: on Windows). On a heavy pipeline (large CSV imports, big SQL joins, multi-million-row intermediate datasets) the WORK library can balloon into tens of GB. If your OS drive is small or near-full, SAS will error out partway through with messages like:

```
ERROR: Insufficient space in file WORK.QUARTERLY_2015.DATA.
ERROR: File WORK.QUARTERLY_2015.DATA is damaged. I/O processing did not complete.
```

`batch_run_sas()` reads an optional `SAS_WORK_DIR` environment variable and, when set, passes `-WORK <path>` to SAS so the WORK library lands wherever you tell it. To enable it, add a line to your `.env`:

```
SAS_WORK_DIR=D:/sas-work
```

(Pick any local-fast-disk folder with ample free space — local SSD, not a network mount.) The folder is created automatically on first run.

If `SAS_WORK_DIR` is unset or empty, `batch_run_sas` does not pass `-WORK` and SAS falls back to its default. You only need to set this if you actually hit the "Insufficient space" failure mode; coauthors with plenty of OS-drive space can leave it alone.


## Macro inventory: what's in `MACROS.sas`

A copy-pasteable reference for the macros that make the example above work. Each one is defined in [`MACROS.sas`](MACROS.sas):

- **`%load_env`** — parses a `.env` file (KEY=VALUE per line) and sets each entry as a global SAS macro variable. After `%load_env;` you can write `libname raw "&RAW_DATA_DIR";` and the path resolves from `.env`. SAS doesn't ship a community dotenv package, so this fills the gap. Pass `%load_env(file=...)` to override the default path derivation.
- **`%tddays`** — build a trading-day window relative to an event date using a CRSP trading-day calendar.
- **`%tdmins`** — same idea but at minute granularity, for intraday work.
- **`%winsor`** — winsorize variables at user-supplied percentiles (e.g., 1%/99%).
- **`%ff12` / `%ff49`** — apply Fama-French 12-industry / 49-industry classifications from a SIC code (originally from <https://github.com/JoostImpink/fama-french-industry>).
- **`%iclink`** — WRDS's standard CRSP-IBES linking macro, lightly wrapped so it auto-points at WRDS libraries when you sign on.


## Why this lives in `example-project` rather than a template

The hub README treats `example-project` as the home for teaching artifacts that don't fit cleanly into the language-specific template repos. SAS isn't part of `project-template`'s pipeline, so adding `MACROS.sas` to that repo would imply more SAS support than it actually provides. Keeping it here means `project-template` stays focused on the language combos it actually supports, while readers who want SAS still have a copy-pasteable starting point — anchored against the [`consensus`](https://github.com/eweisbrod/consensus) repo as a working real-world example.

For more on the `.env` convention this macro file is built around, see the [hub README](../README.md) and the [Environment variables and .env](../topics/environment-variables.md) topic.
