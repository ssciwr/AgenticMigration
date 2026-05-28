---
description: Implementation loop workflow prompt — thin entrypoint for applying the implementation-loop skill after BDD specs and tests are approved.
---

# Implementation Loop Workflow

Apply the `implementation-loop` skill after the BDD review loop is complete. This prompt is an entrypoint, not a second copy of the implementation protocol.

## Required inputs

Ask for any missing required input before starting.

- `source_repo`: path to the legacy/source repository or subpackage used as the behavioral reference.
- `output_repo`: path to the target migrated-code repository where implementation happens.
- `artifact_dir`: discovery artifact directory containing the approved migration artifacts.
- `plan_file`: approved migration plan. Default: `<artifact_dir>/plan.md`.
- `characterization_report`: characterization report. Default: `<artifact_dir>/characterization-report.md`.
- `spec_dir`: directory containing approved BDD specs. Default: `<output_repo>/specs`.

## Optional inputs

Ask only when needed.

- `test_dir`: directory containing executable BDD tests, if not inferable from the target repository.
- `test_command`: focused command for running module-level BDD tests.
- `implementation_report_dir`: directory for module implementation reports when no remote/PR flow exists. Default: `<output_repo>/implementation-reports`.
- `module_filter`: optional subset of the approved plan tree to implement.
- `parallelism`: whether independent modules at the same bottom-up level may be implemented in parallel.

## Invocation template

The human can provide inputs in this shape:

```text
source_repo: /path/to/legacy/repo/or/subpackage
output_repo: /path/to/new/repo
artifact_dir: /path/to/new/repo/discovery
plan_file: optional, defaults to <artifact_dir>/plan.md
characterization_report: optional, defaults to <artifact_dir>/characterization-report.md
spec_dir: optional, defaults to <output_repo>/specs
test_dir: optional
test_command: optional
implementation_report_dir: optional, defaults to <output_repo>/implementation-reports
module_filter: optional
parallelism: optional
```

## Workflow components

This prompt coordinates the implementation skill with the general-purpose implementation and review agents:

- Skill: `skills/implementation-loop/SKILL.md` — authoritative bottom-up implementation and review protocol.
- Agent: `worker` — implements each module against its plan entry, interface contract, approved BDD spec, and executable BDD tests.
- Agent: `reviewer` — reviews each module against the plan acceptance criteria, BDD test results, interface contract, and non-behavioral constraints.

The prompt is only the entrypoint that wires these pieces together.

## Rules

- Treat the `implementation-loop` skill as authoritative.
- Do not duplicate, reinterpret, or override the skill's traversal protocol.
- The parent agent owns orchestration, human gates, and final decisions.
- Load and apply `skills/implementation-loop/SKILL.md` before doing implementation work.
- Delegate implementation to `worker` when available.
- Delegate review to `reviewer` when available.
- Preserve the skill's bottom-up traversal, worker-reviewer iteration loop, level approval gates, implementation-report requirements, and handling of underspecified cases.
- Do not begin until the BDD review loop is complete: BDD specs are approved, BDD step definitions exist, and unit tests (leaf nodes) or integration tests (integration nodes) are written for the modules being implemented.
- Run focused module-level tests — both BDD and unit/integration — rather than broad full-suite commands unless the skill or human explicitly requires otherwise.
- Reviewer must check dependency interface compliance explicitly for each module; BDD test coverage alone is not sufficient.
- Do not expand scope beyond the approved migration plan and BDD specs.
- Check if modules at the same bottom-up level are independent and can be implemented in parallel with worktree-isolated worker subagents. Ask the user before employing parallelization.
- Take into account fundamental dependencies that shape the behavior of a subsystem, e.g., torch for machine learning systems, Eigen3 in C++ for numerics work, or sqlite3 when working with databases.

## Expected outputs

Follow the `implementation-loop` skill for exact placement and completion criteria. At minimum, the workflow should produce:

- Implemented target-language modules in `<output_repo>`.
- Passing BDD tests and passing unit tests (leaf nodes) or integration tests (integration nodes) for each implemented module, or explicit blockers requiring human decision.
- One implementation report per module, either as a PR description when a remote/PR workflow exists or under `implementation-reports/` / the provided `implementation_report_dir`. Each report must include BDD test results, unit/integration test results, and dependency interface compliance verification.
- Human-reviewed approval/revision decisions at each bottom-up level before ascending.

## Completion response

When the skill completes, respond with "Implementation loop complete" and name the implementation report locations and final test status.

If blocked, respond with the smallest set of questions or decisions needed to continue, grouped by module and decision type.
