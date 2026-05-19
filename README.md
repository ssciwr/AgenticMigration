# Agentic workflow tools for [Pi](https://pi.dev/)

## Prerequisites
- pi-subagent plugin installed

## Skills

- [repo-overview](./repo-overview/SKILL.md): Generates a single-page HTML overview of an unfamiliar codebase covering a class diagram, a module diagram, descriptions of each class and module, the test and fixture layout, how to run the tests or the main entry point, and risks or open questions for new contributors. The output is written to scout/overview.html inside the target repository. Use whenever the user asks to scout, explore, document, summarize, onboard onto, or get an overview of a codebase or repository, even if they do not use the word "overview" explicitly.
Uses the 'scout' subagent.