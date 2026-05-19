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
6. After writing, re-open the file and verify it against the checklist below. Correct any syntax errors.
7. Check that paths and call instructions are correct when describing how to run tests, how to use cmake or how to run any callable assets in the repository. Make sure they follow the syntax of the appropriate shell of the user's environment and are adjusted to the user's platform.
8. Go through the checklist in `references/checklist.md` and make sure you completed the workflow completely.
9. Return the path to the final output file, with a short one sentence message like "overview written to <path>/scout".

## Required content

The HTML must include:
- a list of the tech stack involved: languages, frameworks, libraries, and tools used in the codebase which are used in the central parts of the project, e.g., QT6 for GUI, cmake for build, catch2 or pytest for testing, jax or torch for machine learning, etc.
- A note about the dominant coding and testing paradigms used in the codebase
- a class diagram. This should include functions and other code entities part of the data flow too.
- a short description of each class
- a module diagram
- a description of each module
- tests and fixtures and to which parts of the codebase they relate
- how to run tests, or the main entry point if the codebase is a runable application
- any constraints, risks, or open questions about the codebase that would be relevant for a new contributor or someone trying to understand how to make changes in this area.
- add in a pointer to the documentation if it exists

## Verification

After writing `scout/overview.html`, re-read the file and confirm that every required section above is present, diagrams render without broken syntax, and there are no stray markdown or HTML artifacts. Fix anything broken before returning. The final response is only the output file path.
