---
title: Using a template
nav_order: 6
---

# Using a template

Each of the two companion repositories is a GitHub **template repository**. Use the green **Use this template → Create a new repository** button on the template's GitHub page to spin up your own copy:

1. Open the template you want — e.g. <https://github.com/eweisbrod/project-template>.
2. Click **Use this template → Create a new repository**. Pick a name and visibility (public or private). This creates a brand-new repository (repo) in your account with the template's contents but no fork relationship to the original.
3. Clone your new repo to a local folder on your computer using RStudio (File → New Project → Version Control → Git) or `git clone` from the command line.
4. Follow the template's own README for setup (running its `setup.R` / `setup.py`, configuring `.env`, storing WRDS credentials in keyring).

> **Important:** I recommend that you do not put the local clone inside Dropbox. Git and Dropbox can interact badly unless you are an advanced user. Keep your code on a regular drive (e.g. `C:/_git/your-project/`) and put your raw and derived data inside Dropbox separately — the templates' `.env` configuration is built around exactly that split via `RAW_DATA_DIR` and `DATA_DIR`.

If you are not yet ready to spin up your own copy, you can browse the code on each template's GitHub page and copy/paste the parts that are useful to you, or download a zip from any repo's "Code" button.
