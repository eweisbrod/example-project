---
title: About AGENTS.md
parent: In-depth topics
nav_order: 50
---

# About AGENTS.md — AI Assistant Configuration

Each repo in this hub (this one and the two template repos) ships with an `AGENTS.md` file in its root. This is part of an emerging open standard for giving AI coding assistants (Claude Code, GitHub Copilot, Cursor, Windsurf, etc.) context about a project. Below are some teaching notes about what it is and why we include it.

<details open markdown="block">
<summary>On this page</summary>

1. TOC
{:toc}

</details>

## What is AGENTS.md?

`AGENTS.md` is a markdown file in the root of a repository that provides AI assistants with structured information about the project: how it's organized, what conventions to follow, what common pitfalls to avoid. Think of it as a "README for AI" — just as `README.md` helps *humans* understand a project, `AGENTS.md` helps *AI assistants* understand it.

## Why is it called AGENTS.md?

The name was proposed as a **cross-tool standard** by the Linux Foundation's AI Agent Configuration working group, with backing from Anthropic, OpenAI, Google, Amazon, and others. The idea is that one file can work across all AI coding tools instead of separate config files per tool (`.cursorrules`, `CLAUDE.md`, `.github/copilot-instructions.md`, etc.).

## Why include it in these repos?

1. **Teaching by example** — since these are teaching repositories, we want to demonstrate modern development practices, including how to work with AI assistants.
2. **It helps AI assistants help you** — if you open a template in an AI-enabled editor, the assistant automatically reads `AGENTS.md` and understands the project structure, the `.env` convention, the script execution order, and other important details. This makes the AI much more helpful when you ask it questions.
3. **It documents project conventions** — even if you never use an AI assistant, `AGENTS.md` is good complementary documentation about how the project is structured.

## What about CLAUDE.md?

You may also see a `CLAUDE.md` file. This is a thin file specific to [Claude Code](https://docs.anthropic.com/en/docs/claude-code). It uses the `@AGENTS.md` import syntax to pull in the shared context from `AGENTS.md` and adds Claude-specific instructions. The layered approach:

- **AGENTS.md** = shared context that works with *any* AI tool (committed to git)
- **CLAUDE.md** = Claude-specific settings that import AGENTS.md (committed to git)
- **Tool-specific files** (e.g., `.cursorrules`) = can also import or reference AGENTS.md

## Should I create AGENTS.md for my own projects?

Yes, if you use AI coding assistants. Even a short AGENTS.md with your project's key conventions, file structure, and common pitfalls can significantly improve the AI's responses. You don't need to write it from scratch — you can ask an AI assistant to draft one based on your project, then review and edit it.

For more information on the standard, see:

- [Linux Foundation AI Agent Configuration](https://www.linuxfoundation.org/press/linux-foundation-launches-open-standard-for-configuring-ai-coding-agents)
- [Claude Code documentation on CLAUDE.md](https://docs.anthropic.com/en/docs/claude-code/memory)
