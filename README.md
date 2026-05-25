> 📖 **Best viewed as rendered docs here:** <https://eweisbrod.github.io/example-project/>
>
> 📝 **If you use these materials, please cite as follows.** A formal citation will appear here once the companion paper is published. Until then, please link or attribute to <https://github.com/eweisbrod/example-project>.

![example-project](https://socialify.git.ci/eweisbrod/example-project/image?description=1&font=Inter&forks=1&issues=1&name=1&owner=1&pattern=Solid&pulls=1&stargazers=1&theme=Light)

This repository is the **hub** for a set of teaching materials on developing a reproducible empirical research project. The example is primarily designed for empirical business researchers in accounting and finance, but can be adapted for any type of academic journal article. This hub hosts the paper that describes the materials, this README, in-depth topic notes, and pointers to two companion template repositories that hold the actual code:

- **[`project-template`](https://github.com/eweisbrod/project-template)** — a swiss-army-knife research-pipeline template. Ships parallel **R** and **Python** implementations of every numbered pipeline step (download, transform, figures, analyze, provenance), plus a **Stata** implementation of the analyze/tables step that reads the `.dta` written by either the R or Python transform. On first run, the template asks you to pick a language combination (Full R, Full Python, Python + R, Python + Stata, R + Stata, or all three) and prunes the irrelevant files so your project ends up focused on the stack you actually use.
- **[`overleaf-template`](https://github.com/eweisbrod/overleaf-template)** — the LaTeX paper template. Demonstrates the table and figure outputs from the coding template and includes citation, hypothesis numbering, and section-structure examples. Live on Overleaf at <https://www.overleaf.com/read/ctmwnmdcypzh>.

The example pipeline runs an earnings-announcement event study: it computes unexpected earnings (UE) and tests whether the three-day buy-and-hold abnormal return is amplified when the seasonal sales change agrees with the seasonal earnings change (a `UE × SameSign` interaction).

The goal of this hub is to help researchers go from zero to a reproducible publication-ready research document as quickly as possible. Clean, version-controlled project workflows are emphasized throughout in order to generate reproducible tables and figures using code designed to satisfy academic journal code submission policies. The reusable GitHub templates can also help experienced researchers (myself included) quickly jumpstart new project repositories. Lastly, these materials provide good table-formatting examples for PhD students and junior colleagues to encourage them to produce polished work products that facilitate readers' understanding of their work.

An example of an accepted paper using the tools from these examples to prepare a JAR-compliant code package appears at:

- **Paper:** Larocque, S. A., Watkins, J., and Weisbrod, E. H. (forthcoming). "Consensus? An Examination of Differences in Earnings Information Across Forecast Data Providers." *Journal of Accounting Research* (in production).
- **DOI:** [10.1111/1475-679x.70072](https://doi.org/10.1111/1475-679x.70072) *(activates once Wiley completes production)*
- **Companion GitHub repository:** <https://github.com/eweisbrod/consensus>



## What's in this hub

| Page | What's there |
|---|---|
| [Companion templates](pages/companion-templates.md) | The two GitHub template repos this hub points at and how they fit together. |
| [JAR Data and Code Sharing Policy](pages/jar-data-policy.md) | How `project-template` is structured to satisfy the *Journal of Accounting Research*'s data-and-code-sharing policy. |
| [Prerequisites](pages/prerequisites.md) | Software (Git, R, Python, Stata) and account (WRDS, GitHub) requirements for using the templates. |
| [Using a template](pages/using-a-template.md) | Step-by-step on spinning up your own copy of a template via GitHub's "Use this template" button. |
| [In-depth topics](topics/) | Chapter-length notes — project structure for research, Git and GitHub, environment variables and `.env`, the AGENTS.md / AI-assistant conventions, the SAS macros reference, plus planned chapters on WRDS credentials and the raw/derived data split. |
| [Additional resources](pages/additional-resources.md) | Pointers to related books, course materials, and data sources. |
| [Contributing](CONTRIBUTING.md) | How to file issues, suggest changes, or seek support across the three repos. |


## License

This hub and its companion templates are licensed under the
[Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/)
(CC-BY-4.0) license. You can fork, modify, and use these materials
in your own teaching or research as long as you provide attribution.
See [LICENSE](LICENSE) in each repo for the full legal code.
