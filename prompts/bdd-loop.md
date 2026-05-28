---
description: Intent-engineering and specification workflow — helps the human discover and approve what they want the migrated system to do, grounded in the characterization of the legacy code.
---

# Specification and Intent Review Loop

Apply the `bdd-review-loop` skill to an approved migration plan. This prompt is an entrypoint, not a second copy of the protocol.

The purpose of this phase is **intent-engineering**: a structured process by which the human — who may not know the legacy code deeply — uses the characterization findings to discover what they want the migrated system to do and explicitly signs off on it. The output is a set of human-approved specifications that drive all subsequent testing and implementation.

## Required inputs

Ask for any missing required input before starting.

- `source_repo`: path to the legacy/source repository or subpackage being migrated.
- `output_repo`: path to the target migrated-code repository.
- `artifact_dir`: discovery artifact directory containing the approved migration artifacts.
- `plan_file`: approved migration plan. Default: `<artifact_dir>/plan.md`.
- `requirements_file`: approved requirements. Default: `<artifact_dir>/requirements.md`.
- `characterization_report`: characterization report. Default: `<artifact_dir>/characterization-report.md`.

## Optional inputs

Ask only when needed.

- `spec_dir`: directory for BDD specifications. Default: `<output_repo>/specs`.
- `test_dir`: directory for executable tests when no project convention exists.
- `module_filter`: optional subset of the approved plan tree to process.

## Invocation template

The human can provide inputs in this shape:

```text
source_repo: /path/to/legacy/repo/or/subpackage
output_repo: /path/to/new/repo
artifact_dir: /path/to/new/repo/discovery
plan_file: optional, defaults to <artifact_dir>/plan.md
requirements_file: optional, defaults to <artifact_dir>/requirements.md
characterization_report: optional, defaults to <artifact_dir>/characterization-report.md
spec_dir: optional, defaults to <output_repo>/specs
test_dir: optional
module_filter: optional
```

## Workflow components

This prompt coordinates the BDD-specific skill and agents shipped with this workflow repository:

- Skill: `skills/bdd-review-loop/SKILL.md` — authoritative traversal and review protocol.
- Agent: `agents/bdd-spec-writer.md` — drafts module-level BDD specifications for human approval.
- Agent: `worker` — converts approved BDD specifications into executable tests.

The prompt is only the entrypoint that wires these pieces together.

## Prerequisites

Before the loop starts, verify that the approved plan file has `node_type` and `dependency_interfaces` populated for every module. If any module is missing either field, surface it as a blocking question to the human before proceeding.

## Rules

- Treat the `bdd-review-loop` skill as authoritative.
- Do not duplicate, reinterpret, or override the skill's traversal protocol.
- The parent agent owns orchestration, human gates, and final decisions.
- Load and apply `skills/bdd-review-loop/SKILL.md` before doing any BDD spec or test work.
- Delegate BDD specification drafts to `agents/bdd-spec-writer.md` / `bdd-spec-writer` when available.
- Delegate executable test implementation to `worker` agent when available. This can be run in the background if possible too.
- Adhere to the skill's breadth-first traversal, sibling review gates, partial approval behavior, and context-scoping rules.
- Check if tasks can be parallelized with subagents. This might apply to same-level tasks in particular. Ask the user if you should parallelize and employ parallelization of test writer work with subagents if the user approves it.
- When passing characterization context to bdd-spec-writer, extract only the findings by ID referenced in that module's plan entry — do not pass the full characterization report.
- Do not begin until the migration plan is approved by the human or the user confirms approval in the current conversation.
- Do not write production implementation code during this workflow.
- Prefer a real target-language BDD framework where viable (for example, `Behavior.jl` for Julia, `pytest-bdd`/`behave` for Python) instead of approximating Gherkin scenarios with broad hand-written tests.
- Package/test dependency setup for the selected BDD framework is part of this workflow and should be completed before or alongside executable step definitions.
- take into account fundamental dependencies that shape the behavior of a subsystem, e.g., torch for machine learning systems, Eigen3 in C++ for numerics work or sqlite3 when working with databases.

## Expected outputs

Follow the `bdd-review-loop` skill for exact placement and completion criteria. At minimum, the workflow should produce:

- For each **leaf node**: an interface contract specification (`.md`) under `specs/` or the provided `spec_dir`, human-approved; and unit tests in the target repository's existing test structure.
- For each **integration or entry-point node**: a Gherkin feature file (`.feature`) under `specs/` or the provided `spec_dir`, human-approved, with a `Dependency interface coverage` section; BDD step definitions and integration tests in the target repository's existing test structure, or `test_dir` if provided.
- BDD framework package/test configuration (for integration/entry-point nodes) where a viable framework exists.
- Human-reviewed approval/revision decisions at each breadth-first level.

## Completion response

When the skill completes, respond with "BDD review loop complete" and name the spec and test locations.

If blocked, respond with the smallest set of questions or decisions needed to continue, grouped by module and decision type.
