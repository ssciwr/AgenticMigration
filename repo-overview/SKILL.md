---
name: repo-overview
description: Generates a single-page HTML overview of an unfamiliar codebase covering a class diagram, a module diagram, descriptions of each class and module, the test and fixture layout, how to run the tests or the main entry point, and risks or open questions for new contributors. The output is written to scout/overview.html inside the target repository. Use whenever the user asks to scout, explore, document, summarize, onboard onto, or get an overview of a codebase or repository, even if they do not use the word "overview" explicitly.
---

# Repo Overview
Understand the codebase in the /mnt/dataLinux/Development/QuantumGrav repository  for a new contributor. Do not modify or write any files. Inspect the
repository structure, source code, tests, fixtures, CI/config/tooling. Return concise but complete findings needed to create an HTML overview with: class diagram, short description of each class, module diagram, description of each module, starting reading points, entry points for relevant code paths and CI tools, tests/fixtures and what code they relate to, how to run tests and what they cover, constraints/risks/open questions. Include file paths and relationships. If diagrams are appropriate, provide Mermaid classDiagram and flowchart/module diagram source. Also include free functions into the class diagram if they are functionally important.  Do not create artifacts. Please
write your findings into an html file for rendering in a browser so the new dev can read through it at the base
directory of the repository
In more detail:

Come back with:
- a class diagram. This should include functions and other code entities part of the data flow too.
- a short description of each class
- a module diagram
- a description of each module
- tests and fixtures and to which parts of the codebase they relate
- how to run tests, or the main entry point if the codebase is a runable application
- any constraints, risks, or open questions about the codebase that would be relevant for a new contributor or someone trying to understand how to make changes in this area.
- add in a pointer to the documentation if it exists

After writing the html file, go and check again if it is correct and if it contains all the required information. Correct all syntax errors you find before returning the path to the output file.

## Input

The target repository path is provided as input. When invoked via `/skill:repo-overview <path>`, the path arrives as a user message immediately after the skill body. If no path is supplied, ask the user which repository to scout before proceeding.

## Workflow

1. Use the `scout` agent to understand the codebase at the given path.
2. Read `assets/example.html` to anchor the expected output format and level of detail.
3. Render the findings into a single HTML file at `<repo>/scout/overview.html`.
4. Create a more concise version of this overview into a markdown file in `<repo>/scout/overview.md`.
4. Do not write any other files.
5. Do not dump findings into the conversation.
6. After writing, re-open the file and verify it against the checklist below. Correct any syntax errors.
7. Return **only** the path to the final output file.

## Required content

The HTML must include:
- A module diagram
- A description of each module
- A class diagram
- A short description of each class
- Tests and fixtures, and which parts of the codebase they cover
- How to run the tests, or the main entry point if the codebase is a runnable application
- Constraints, risks, or open questions relevant to a new contributor or anyone making changes in this area
- A pointer to existing documentation, if any

The .md file must contain the same things as the html, but can be shorter.

## Verification

After writing `scout/overview.html`, re-read the file and confirm that every required section above is present, diagrams render without broken syntax, and there are no stray markdown or HTML artifacts. Fix anything broken before returning. The final response is only the output file path.

## Checklist
Go through all the points in the checklist at references/checklist.md and make sure that you did everything that is written down there.
