---
description: Full agentic migration workflow — from legacy codebase to migrated implementation.
---

# Migration Workflow

This workflow migrates a legacy codebase to a target language and stack. It proceeds in three phases, each gated by human approval before the next begins.

Use this prompt as the top-level entrypoint. For more detail, delegate to the phase prompts:

- Phase 1: `prompts/discovery.md`
- Phase 2: `prompts/bdd-review-loop.md`
- Phase 3: `prompts/implementation-loop.md`

## Required inputs

Ask for any missing required input before starting.

- `source_repo`: path to the legacy/source repository or subpackage to migrate.
- `output_repo`: path to the target migrated-code repository.
- `target_language`: target implementation language.

Optional but commonly useful:

- `artifact_dir`: discovery artifact directory. Default: `<output_repo>/discovery`.
- `target_framework`, `migration_scope`, `behavior_policy`, `performance_policy`, `test_policy`, `constraints`, `non_goals`.

## Phase 1 — Discovery

Run the discovery phase using `prompts/discovery.md` :

```text
/discovery -- /path/to/legacy/repo
```

Workflow components:

- Agent: `characterization-tester` — characterizes observable legacy behavior and writes characterization tests/report.
- Skill: `characterization-methodology` — defines characterization evidence and test quality rules.
- Skill/agent: `repo-overview` / `scout` — generates the source repository overview.
- Skill: `requirements-intake` — gathers and validates approved migration requirements.
- Skill/agent: `migration-planner` / `planner` — writes the migration plan.
- Agent: `oracle` — reviews the plan and discovery artifacts for gaps before approval.

Expected artifacts:

- `<artifact_dir>/characterization-report.md`
- `<artifact_dir>/overview-summary.md`
- `<artifact_dir>/requirements.md`
- `<artifact_dir>/plan.md` — each module entry must include `node_type` (leaf/integration) and `dependency_interfaces` (framework/library contracts, or `none` if none apply).
- `<artifact_dir>/oracle-review.md`

Human gate: review `<artifact_dir>/plan.md` and `<artifact_dir>/oracle-review.md`. Resolve blocking questions, approve the plan, or request revisions. Confirm that `node_type` and `dependency_interfaces` are present and resolved for every module. Do not begin BDD work until the plan is approved.

## Phase 2 — BDD specs and tests

Run the BDD phase using `prompts/bdd-review-loop.md`:

```text
Apply the bdd-review-loop prompt to the approved migration plan.
```

Workflow components:

- Skill: `bdd-review-loop` — authoritative breadth-first spec/test review protocol.
- Agent: `bdd-spec-writer` — drafts module-level specifications for human approval: interface contract specs for leaf nodes, Gherkin feature files for integration/entry-point nodes; includes dependency interface coverage.
- Agent: `worker` — converts approved specifications into executable tests.
- Skill: `bdd-writing-quality` — quality rules for Gherkin specs, dependency interface scenarios, the dual test surface, and BDD-to-test traceability.

Expected artifacts:

- For each **leaf node**: an interface contract specification (`.md`) under `<output_repo>/specs`, human-approved; and unit tests in the target repository's test structure.
- For each **integration or entry-point node**: a Gherkin feature file (`.feature`) under `<output_repo>/specs`, human-approved, with a `Dependency interface coverage` section; BDD test definitions and integration tests in the target repository's test structure. BDD scenarios specify behavior independent of the implementation that produces it. Integration tests verify that this implementation, with its chosen modules, dependencies, and framework contracts, produces that behavior when composed.
- BDD framework package/test configuration for integration/entry-point nodes where a viable framework exists.
- Human approval/revision decisions at each breadth-first level.

Human gates: sibling specs at each plan-tree level are reviewed together before tests are written. Confirm dependency interface coverage at each level before descending. Do not descend to the next level until that level's specs are approved and the test artifacts are written, except for explicit human-approved deferrals.

## Phase 3 — Implementation

Run the implementation phase using `prompts/implementation-loop.md`:

```text
Apply the implementation-loop prompt after BDD specs and tests are approved.
```

Workflow components:

- Skill: `implementation-loop` — authoritative bottom-up implementation and review protocol.
- Agent: `worker` — implements each module against its plan entry, interface contract, approved BDD spec, and unit/integration tests.
- Agent: `reviewer` — checks four concerns in sequence per module: correctness · test quality · unnecessary complexity · spec conformance. All four must be `clear` or `advisory` before the module advances.

Expected artifacts:

- Implemented target-language modules in `<output_repo>`.
- Passing BDD tests and passing unit tests (leaf nodes) or integration tests (integration nodes) for each implemented module, or explicit blockers.
- Equivalence of results to corresponding behavior of source repository as defined in characterization tests where such a correspondence exists.
- Implementation reports as PR descriptions when a remote/PR flow exists, otherwise under `<output_repo>/implementation-reports`. Each report includes BDD test results, unit/integration test results, and dependency interface compliance verification.

Human gates: once all modules at a bottom-up level are complete, present their implementation reports together before ascending. Resolve any decisions made on underspecified cases, including any dependency interface choices, before continuing.

## Completion response

When all phases are complete, respond with "Migration workflow complete" and name the key artifact locations, spec/test locations, implementation report locations, and final test status.

If blocked, respond with the smallest set of questions or decisions needed to continue, grouped by phase and module where applicable.
