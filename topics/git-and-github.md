---
title: Git and GitHub
parent: In-depth topics
nav_order: 2
---

# Git and GitHub for research projects

Version control is one of the highest-ROI habits a researcher can pick up. It lets you experiment without fear of breaking working code, lets coauthors edit the same files without overwriting each other, and produces a publication-grade record of how the analysis evolved. This chapter covers the Git and GitHub workflow specifically for running research projects — what tools to use, what commits should look like, how to collaborate, and how to organize a paper as it moves through draft, submission, R&R, and acceptance.

If you're brand new to Git, the canonical introduction is Jenny Bryan's [*Happy Git and GitHub for the useR*](https://happygitwithr.com/). It covers installation, RStudio integration, and the mechanics of every Git operation in more depth than this chapter does. The chapter below assumes you've gotten through Happy Git's setup (or equivalent) and focuses on the conventions specific to running a reproducible research project on top.

<details open markdown="block">
<summary>On this page</summary>

1. TOC
{:toc}

</details>

## Git vs. GitHub

These two get conflated constantly. They're related but distinct:

- **Git** is the version-control system: software that runs on your computer and tracks changes to files. Every Git operation (commit, branch, merge, diff) happens locally. You can use Git without an internet connection. You can use Git without GitHub.
- **GitHub** is a web service that hosts Git repositories on the internet. It adds collaboration features Git doesn't have by itself: issues, pull requests, project pages, GitHub Actions for CI, and a UI for browsing repos in a browser. GitHub competitors exist (GitLab, Bitbucket); they all do roughly the same thing.

A typical research project uses both: Git locally to track day-to-day changes, GitHub as the canonical remote copy that lives in the cloud and that coauthors `pull` from. The relationship is the same as a Dropbox folder backed up to dropbox.com — you do work locally, then sync the result to a shared remote.

A useful analogy: **`git clone` is to a GitHub repo what installing Dropbox on a new computer is to your Dropbox folder.** You point at the remote, and a local working copy materializes. From then on you keep them in sync.

## Why use them for research

- **Reproducibility on demand.** Every commit is a snapshot of the code at a moment in time. If a reviewer asks "what did the analysis look like before you added that control?" you can answer with a commit hash, not a guess.
- **No more `analysis_v3_FINAL_jw_edits.R`.** Git replaces filename-version sprawl with one file per script and a commit history.
- **Coauthor collaboration without overwriting.** Two collaborators can edit different scripts (or even different sections of the same script) and Git merges the changes. Compare to emailing `.R` files back and forth.
- **Replication packages.** When you ship to JAR / RFS / JFE / a JOSE submission, the replication package *is* the repo. Tag a release at submission time and a reviewer downloads exactly what you ran.
- **A free off-site backup.** Your laptop dies; you `git clone` to a new one and you're back where you started.

## The everyday workflow

The minimum-viable Git workflow:

```bash
# edit some files in your editor
git add <files>           # stage what you want to commit
git commit -m "message"   # snapshot the staged changes
git push                  # send to GitHub
```

And to bring in changes from a coauthor:

```bash
git pull                  # fetch and merge from GitHub
```

A reasonable cadence for a research project:

- **Commit when you finish a meaningful change** — fixed a bug, added a control, rewrote a section. Not every save; not once a week.
- **Push at least daily** when anyone else is on the project. The remote is your off-site backup.
- **Pull before you start working** when anyone else is on the project. Saves you the merge conflict.

### Writing good commit messages

A commit message should answer "what did this commit change and why?" in one line.

- ❌ `fix bug`
- ❌ `updates`
- ❌ `wip`
- ✅ `fix off-by-one in 002-transform: fyearq filter used > instead of >=`
- ✅ `add SameSign control to baseline regression in 004-analyze`
- ✅ `bump RAW_DATA_DIR snapshot to 2025-07-18 ibes pull`

Future-you reads these messages when answering reviewer questions six months later. Be specific.

## GitHub from RStudio vs. the terminal

You can drive Git from three places, and most researchers settle on a mix:

- **The RStudio Git pane** (top-right tab) — point-and-click for `commit`, `push`, `pull`, `diff`. Best for everyday committing while you're already in RStudio. Comfortable for people new to Git.
- **The terminal** (`git` on the command line) — full power, all operations available. Best for branching, merging, resolving conflicts, anything beyond the basics. The interface most documentation and Stack Overflow answers assume.
- **GitHub Desktop** (separate app) — point-and-click, polished UI, works outside RStudio. Good middle ground if you don't use RStudio or want a dedicated Git client.

A common pattern: **RStudio Git pane** for routine commits during a coding session; **terminal** for `git log`, `git branch`, `git merge`, conflict resolution, anything weird. Don't feel obligated to commit to one interface — they're working on the same underlying repo, so it doesn't matter which one you used five minutes ago.

## Template repositories (the "Use this template" button)

The hub's companion repos — [`project-template`](https://github.com/eweisbrod/project-template) and [`overleaf-template`](https://github.com/eweisbrod/overleaf-template) — are GitHub **template repositories**, which behave differently from forks:

- A **fork** preserves the relationship to the original. Forks are for proposing changes back to the source.
- A **template-derived repo** has no relationship to the original. It's a clean starting point for your own project that happens to come with template content pre-filled. The original maintainer has no access to or visibility into your work.

To use a template: open the template repo on GitHub, click the green **Use this template → Create a new repository** button, name your new repo and pick its visibility, and clone it locally. Done — you now own the repo.

This is the right mechanism when you're starting a research project from a template you don't expect to contribute back to.

## Private repos and the GitHub Education benefits

GitHub repositories can be **public** (anyone can read) or **private** (only invited collaborators can read). For ongoing research you almost always want private — interim regression specifications, draft results, and unreleased data identifiers don't need to be on the public internet.

Two ways to get private repos:

- **GitHub Free** gives unlimited private repos with up to 3 collaborators. Fine for solo work and small teams.
- **GitHub Pro** (free for academics and students via [GitHub Education](https://education.github.com/benefits) with a `.edu` email) removes the collaborator cap, adds monthly GitHub Copilot tokens, and includes a stack of other developer tools. Worth doing — it's free and takes ten minutes.

## `.gitignore` for research projects

A research project accumulates a lot of files that shouldn't be in git: raw data downloads, machine-specific config, log files, build artifacts, OS clutter. The `.gitignore` at the project root tells Git which patterns to never track.

A defensive baseline for a research project:

```gitignore
.env                  # local config; sometimes contains secrets
log/                  # script execution logs (regenerable)
output/               # generated tables and figures (regenerable)
*.parquet             # data files
*.sas7bdat
*.dta
.DS_Store             # macOS clutter
Thumbs.db             # Windows clutter
.Rproj.user/          # RStudio session state
__pycache__/          # Python bytecode
```

Rule of thumb: **anything that can be regenerated by running the code shouldn't be in git.** Logs regenerate. Derived parquets regenerate. Tables and figures regenerate. None of those belong in version control.

See [Project structure for research](project-structure.md) for the broader code-vs-data split that motivates this.

## Branching for "what if" analyses and R&R revisions

A Git **branch** is a parallel line of development. You can experiment on a branch without disturbing the main work, then either merge the result back in or throw the branch away. Branches are cheap — Git just bookmarks a commit and lets you grow a separate history from there.

Two specific patterns are unusually high-leverage for research:

- **Alternative-specification branches.** A reviewer asks "what if you cluster differently?" Create `revisions-r1/cluster-by-firmyear`, do the alternative, commit. If it survives the review, merge it. If not, the branch lives in history as evidence you tried.
- **R&R revision branches.** Each round of revision gets its own branch (`revisions-r1`, `revisions-r2`). The base `main` branch keeps the originally-submitted state; the revision branch holds the requested changes. When the revision is accepted, merge the branch into `main` and tag the result.

The everyday commands:

```bash
git checkout -b revisions-r1            # create and switch to a new branch
# ... edit and commit ...
git push -u origin revisions-r1         # publish the branch to GitHub
git checkout main && git merge revisions-r1   # merge back when ready
```

Use branches whenever the answer to "should this experiment be in the same history as my main work?" is "not yet."

## Tags for paper versions

A **tag** is a permanent label on a specific commit. Unlike branches (which move as you commit), tags are anchored. They mark moments worth coming back to.

For papers, tagging the commit you submitted at each review round preserves the exact state a reviewer saw:

```bash
git tag -a v0-submitted -m "Initial submission to JAR"
git tag -a v1-r1-revision -m "First-round R&R response"
git tag -a v2-accepted -m "Accepted version"
git push --tags
```

When the paper is accepted, tag the final state (`v1-jar-accepted` or similar) and point the journal's replication-package URL at that tag. Anyone replicating the published paper downloads exactly that snapshot, not a moving target.

GitHub's UI also exposes tags as **Releases** with optional attached binaries — useful if you want to bundle the final data files alongside the code at acceptance time.

## Collaboration: issues, discussions, pull requests

GitHub's collaboration features layer on top of the basic Git workflow:

- **Issues** — track tasks, bugs, and to-dos for the project. "Try the alternative specification with HML controls." "Figure 3 has the wrong title." Issues stay open until someone closes them, ideally with a commit that fixes them. Searchable forever, which is more than email threads can claim.
- **Discussions** — open-ended conversation that isn't a task. Good for "what's our plan for the second-stage robustness checks?"
- **Pull requests (PRs)** — propose changes from a branch to be merged into another branch. Most useful when one coauthor wants another to review specific changes before they land on `main`.

For a typical 2-3 person research project, **issues for tasks and direct commits to main** is usually enough. PRs add overhead worth it for larger groups but excessive for a solo paper.

## A small GitHub glossary

The terms that come up constantly:

| Term | Meaning |
|---|---|
| **Repository** (repo) | A project's folder, with all its files and the complete change history. |
| **Clone** | Make a local working copy of a remote repo. `git clone <url>`. Once done, the clone stays linked to the remote and can `push`/`pull`. |
| **Commit** | A snapshot of the project's files at one moment, with a message describing what changed. |
| **Branch** | A parallel line of commits. Lets you develop alternatives without disturbing `main`. |
| **Merge** | Combine the changes from one branch into another. |
| **Pull request (PR)** | A formal request to merge one branch into another, with a UI for review. |
| **Push** | Send your local commits to the remote. |
| **Pull** | Fetch the remote's commits and merge them into your local branch. |
| **Origin** | The default name for the remote — usually your repo on GitHub. |
| **Main** | The default name for the primary branch. (Older repos sometimes call it `master`.) |
| **Tag** | A permanent label on a specific commit, used for version markers. |
| **Issue** | A GitHub-tracked item (bug, task, question) that lives on the repo. |
| **Fork** | A personal copy of someone else's repo, with the relationship preserved. Different from a template-derived repo. |

## Common gotchas

A few things that bite first-time users:

- **Don't put your local clone inside Dropbox.** Git and cloud-sync clients fight over the `.git/` folder and silently corrupt repos. See [Project structure for research](project-structure.md).
- **Never commit `.env` or any file containing credentials.** Even after you delete it, Git remembers — your password is in history forever. If it happens, change the password immediately rather than trying to scrub history.
- **`git push` from RStudio's Git pane has a "Force push" checkbox.** Don't check it unless you specifically intend to overwrite history on the remote. Force-push is how coauthors lose work.
- **Merge conflicts happen.** When two coauthors edit overlapping lines, Git stops and asks you to resolve. Don't panic; open the conflicted file, find the `<<<<<<< HEAD` markers, edit to keep what you want, `git add` the resolved file, commit. Awkward the first time and routine the second.
- **`git status` is your friend.** When you're unsure what Git thinks is going on, `git status` shows the current state — what's staged, what's modified, what branch you're on, whether the local branch is ahead or behind the remote.

## See also and further reading

- [*Happy Git and GitHub for the useR*](https://happygitwithr.com/) — the canonical introduction. Covers installation, RStudio configuration, and every Git operation in detail.
- [*Pro Git*](https://git-scm.com/book/en/v2) — the official Git book. Free online. The definitive reference if you want to understand what Git is actually doing under the hood.
- [GitHub Education](https://education.github.com/benefits) — student/academic benefits including free Pro accounts.
- [Project structure for research](project-structure.md) — the broader project-layout context this chapter slots into.
- [About AGENTS.md](agents-md.md) — once you have a project in GitHub, AI coding assistants read `AGENTS.md` from the repo root for project context.
