---
title: Replication packages and what data editors expect
parent: In-depth topics
nav_order: 8
---

# Replication packages and what data editors expect

At some point between "the regression works" and "the paper is
published," most journals in accounting, finance, and economics will ask
you for a **replication package**: the code, the documentation, and
sometimes the data behind every number in the manuscript. This note
explains what the major policies actually require, where they disagree,
and which parts of the package the templates in this hub produce for you.

The short version: the field has settled on a small, stable set of
artifacts, and the templates emit most of them as a by-product of
running the pipeline. The parts they cannot produce are the parts that
depend on your manuscript rather than your code.

<details open markdown="block">
<summary>On this page</summary>

1. TOC
{:toc}

</details>

## Two different things journals are asking for

It helps to separate two questions that policies often blur together.

**Disclosure** asks: what did you do, and can someone see it? Its
artifacts are code, logs, sample identifiers, and documentation. This is
what a journal needs to make your work inspectable.

**Verification** asks: does it actually run, and does it produce the
numbers in the paper? Its artifact is a report from someone at the
journal who ran your code.

The distinction matters because the two have moved at different speeds
in different fields, and the field you publish in determines which one
you should worry about.

Economics went to verification early. The American Economic Association
appointed a Data Editor in 2019, and the AEA journals, Econometrica, the
*Journal of Political Economy*, and the *Review of Economic Studies* now
all condition final acceptance on someone re-executing your replication
package. Econometrica states it plainly: full reproducibility is a
prerequisite for final acceptance.

Finance followed, unevenly. The *Review of Financial Studies* has the
most thorough process in the field — its data editors run your code in a
dedicated computing environment and issue a verification report, and
where data cannot be shared, they will invite you to load it into a
secure enclave so the code can be run against the real thing. The
*Journal of Finance* verifies too. The *Journal of Financial Economics*
has a data editor who reviews every package "to ensure they are complete
and organized," which is a completeness audit rather than a
reproduction — a real check, but a different one. The *Journal of
Financial and Quantitative Analysis* validates code for randomly
selected publications.

Accounting has gone the other way: demanding disclosure, no verification.
The *Journal of Accounting Research* has what is arguably the most
demanding author-side artifact list of any journal in the three fields,
and *The Accounting Review* began requiring code submission for
manuscripts conditionally accepted on or after 1 July 2026, with the
other American Accounting Association journals following on 1 July 2027.
But no accounting journal employs a data editor or re-runs any code.
Compliance is self-certified throughout.

That has a practical consequence worth internalizing early. **In
accounting, nothing external will catch a broken pipeline.** No one is
going to run your code before it is published and tell you the sample
counts moved. The discipline has to be your own, which is why the
templates lean so hard on habits like reconciling observation counts
across implementations rather than treating small differences as
rounding noise.

## The artifacts, and which ones the templates produce

Across the major policies, the same items keep recurring. Here is the
full list, with what the templates do about each.

| Artifact | Who asks for it | Templates |
|---|---|---|
| Code that builds the analysis sample from raw data | Nearly everyone | Steps 001–002 |
| Statistical analysis code | Nearly everyone | Step 004 |
| Table- and figure-generating code | AEA, Econometrica, JPE, ReStud, RFS, JFE, JAR | Steps 003–004 |
| Comprehensive execution log | JAR, JF | `batch_run()` writes one per step |
| No manual data steps outside the code | JAR; AEA in guidance | Pipeline design |
| Identifiers for the final sample | JAR | Step 005 |
| Disclosure document at submission | JAR, CAR, JF, Management Science | You write this |
| README in the data editors' format | AEA, Econometrica, ReStud, RFS | `README_replication.md` skeleton |
| List of exhibits mapped to programs | Everyone using that README | Step 005 seeds it |
| File hash inventory | Nobody, yet | Step 005 |

Two entries deserve comment.

The **file hash inventory** is in the templates because it is useful, not
because anyone requires it. Step 005 records a SHA256 hash for every raw,
derived, and output file. That turns "did anything change since I last
ran this?" from a feeling into a checkable fact, which matters most
during a revise-and-resubmit, when you are rerunning a pipeline you last
touched eight months ago.

The **exhibit map** is the one artifact a pipeline genuinely cannot
finish for you. Step 005 lists every file in your output directory and
which scripts mention it, but it cannot know that `regression-r.tex` is
Table 3, because exhibit numbering happens in the manuscript. You fill in
that column; the script preserves what you typed across later runs.

## The README the data editors want

If you publish in economics or in finance, the document that ties all of
this together is the [Social Science Data Editors' README
template][ssde]. It is a community standard maintained by the data
editors of the AEA, the *Review of Economic Studies*, the *Economic
Journal*, and the *Canadian Journal of Economics*, and it has been picked
up by journals beyond that list, including the RFS.

Note who is missing from it: no accounting journal uses the template.
This is the same asymmetry as before. Accounting asks more of individual
authors than economics does, but has built less shared infrastructure for
them to use. If you work in accounting, you are likely to encounter the
template anyway — through a coauthor in finance, or the first time you
send a paper to a journal outside your field.

The template asks for:

- **Overview** — what the code does and how long it takes to run.
- **Data availability and provenance** — where each dataset came from,
  whether you may redistribute it, and how a replicator would get it.
- **Dataset list** — every file, its source, and whether it ships.
- **Computational requirements** — software and package versions,
  hardware, runtime, and whether any randomness is involved.
- **Description of programs** — what each script does.
- **Instructions to replicators** — the actual steps to run it.
- **List of tables and programs** — the exhibit map.
- **References** — proper citations for each data source.

`project-template` ships a `README_replication.md` that answers the parts
it can and marks the rest for you.

## The licensed-data problem

Most of the guidance written about replication packages assumes you can
publish your data. In accounting and finance you usually cannot:
Compustat, CRSP, and IBES are licensed through WRDS, and the licence does
not permit redistribution.

This is not a loophole, and the policies are written with it in mind.
Every major policy has a route for restricted data, and they converge on
the same shape:

1. **Ship the code anyway**, including the code that builds the sample
   from raw data. The code is yours even when the data is not.
2. **Document how to get the data**, precisely enough that someone at a
   subscribing institution can obtain the same extract — including the
   *download date*, because WRDS data are restated over time and a
   rerun three years later will not return the same raw extract.
3. **Ship something that stands in for the data.** Policies differ on
   what. JAR wants identifiers for the final sample. Economics and
   finance journals more often want *pseudo data* or a synthetic dataset
   with enough rows that the code runs end to end. Some journals want
   both.

The identifier route is worth dwelling on, because it is the one that
does real work for a replicator. If you ship the `gvkey`, `permno`, and
announcement date of every firm-quarter in your final sample, another
researcher with WRDS access can rebuild your sample and check whether
they got the same rows. If they did not, the mismatch tells them exactly
where the divergence is. Without identifiers, all they can do is compare
coefficients and guess.

Step 005 writes those identifiers for you, in both Parquet and CSV.

## What this means for how you work

Two habits follow from all of this, and they are cheaper to adopt at the
start of a project than to retrofit at submission.

**Make the artifacts fall out of running the pipeline.** The reason the
templates write logs, identifiers, and hashes automatically is that
submission time is the worst possible moment to reconstruct what you did.
By then the analysis is months old, the intermediate files have been
overwritten, and the manual step you took once in Excel has been
forgotten. A pipeline that emits its own documentation on every run has
already answered the question before anyone asks it.

**Build to the strictest policy you might face.** The requirements
overlap heavily, and one policy — JAR's, as revised in April 2024 —
happens to be a superset of the author-side requirements of every other
major journal in accounting, finance, and economics. Build a project that
satisfies it and you have satisfied the rest, which means you only have
to learn one standard rather than one per journal.

## Further reading

- [Social Science Data Editors README template][ssde] — the standard, with
  annotated and ready-to-use versions in Markdown, Word, and LaTeX.
- [AEA Data and Code Availability Policy](https://www.aeaweb.org/journals/data/data-code-policy)
  — the model most other policies descend from.
- [JAR Data and Code Sharing Policy](https://www.chicagobooth.edu/-/media/research/arc/docs/journal/jardatapolicyasof4124.pdf)
  — the strictest author-side artifact list.
- [`project-template`](https://github.com/eweisbrod/project-template) —
  `README_replication.md` in the repository root, and the
  `provenance/` folder for the generated artifacts.

[ssde]: https://social-science-data-editors.github.io/template_README/
