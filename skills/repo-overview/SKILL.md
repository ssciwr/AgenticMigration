---
name: repo-overview
description: >
  Generate a single-page HTML overview of an unfamiliar codebase.
  Use whenever the user asks to scout, explore, document, summarize,
  onboard onto, or get an overview of a codebase or repository.
  Writes scout/overview.html inside the target repository.
---

# Repo Overview
Understand the codebase in the target repository for a new contributor. Inspect the repository structure, source code, tests, fixtures, CI/config/tooling. Return concise but complete findings needed to create an HTML overview with: class diagram, short description of each class, module diagram, description of each module, starting reading points, entry points for relevant code paths and CI tools, tests/fixtures and what code they relate to, how to run tests and what they cover, constraints/risks/open questions. Include file paths and relationships. If diagrams are appropriate, provide Mermaid classDiagram and flowchart/module diagram source. Also include free functions into the class diagram if they are functionally important. Additionally, note the dominat coding and testing paradigms (e.g., unit tests, object oriented programming in GUI, functional programming in numerics part), and list important elements of the tech stack. Please write your findings into an html file for rendering in a browser so the new dev can read through it at the base directory of the repository.

## When to use
- user asks for explanation of a repository structure
- user asks for explanation of a project they have never worked on before
- user asks for succinct representation of a codebase

## Input

The target repository path is provided as input. When invoked via `/skill:repo-overview <path>`, the path arrives as a user message immediately after the skill body. If no path is supplied, ask the user which repository to scout before proceeding.

## Workflow

1. Inspect the repository directly. If a scout/explorer subagent is available and appropriate, use it for a bounded codebase survey to understand the codebase at the given path.
2. Read `references/example.html` only as a visual and structural reference. Reuse the section order, density, and browser-rendered style, but replace all domain-specific content with facts from the target repository. Make sure you capture the entire file structure.
3. Render the findings into a single HTML file at `<repo>/scout/overview.html`.
4. Do not write any other files.
5. Do not dump findings into the conversation.
6. After writing, re-open the file and verify it against the checklist below and correct any syntax errors or errors in the diagrams.
7. Check that paths and call instructions are correct when describing how to run tests, how to use cmake or how to run any callable assets in the repository. Make sure they follow the syntax of the appropriate shell of the user's environment and are adjusted to the user's platform.
8. Go through the checklist in `references/checklist.md` and make sure you completed the workflow completely.
9. Return the path to the final output file, with a short one sentence message like "overview written to <path>/scout".

## Verification

After writing `scout/overview.html`, re-read the file and confirm that every required section as defined in `references/checklist.md` is present, diagrams render without broken syntax, and there are no stray markdown or HTML artifacts. Fix anything broken before returning. The final response is only the output file path.
