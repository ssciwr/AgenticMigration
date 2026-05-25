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

Run the discovery phase using `prompts/discovery.md` or the discovery chain:

```text
/run-chain discovery -- /path/to/legacy/repo
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
- `<artifact_dir>/overview.html`
- `<artifact_dir>/overview-summary.md`
- `<artifact_dir>/requirements.md`
- `<artifact_dir>/plan.md`
- `<artifact_dir>/oracle-review.md`

Human gate: review `<artifact_dir>/plan.md` and `<artifact_dir>/oracle-review.md`. Resolve blocking questions, approve the plan, or request revisions. Do not begin BDD work until the plan is approved.

## Phase 2 — BDD specs and tests

Run the BDD phase using `prompts/bdd-review-loop.md`:

```text
Apply the bdd-review-loop prompt to the approved migration plan.
```

Workflow components:

- Skill: `bdd-review-loop` — authoritative breadth-first spec/test review protocol.
- Agent: `bdd-spec-writer` — drafts module-level BDD specifications for human approval.
- Agent: `bdd-test-writer` — converts approved BDD specifications into executable tests.
- Skill: `bdd-writing-quality` — quality rules for Gherkin specs and BDD-to-test traceability.

Expected artifacts:

- BDD specs under `<output_repo>/specs` unless another `spec_dir` is provided.
- Executable tests in the target repository's test structure.
- Human approval/revision decisions at each breadth-first level.

Human gates: sibling specs at each plan-tree level are reviewed together before tests are written. Do not descend to the next level until that level's specs are approved and tests are written, except for explicit human-approved deferrals.

## Phase 3 — Implementation

Run the implementation phase using `prompts/implementation-loop.md`:

```text
Apply the implementation-loop prompt after BDD specs and tests are approved.
```

Workflow components:

- Skill: `implementation-loop` — authoritative bottom-up implementation and review protocol.
- Agent: `worker` — implements each module against its plan entry, interface contract, approved BDD spec, and tests.
- Agent: `reviewer` — reviews each module against acceptance criteria, BDD test results, and interface contracts.

Expected artifacts:

- Implemented target-language modules in `<output_repo>`.
- Passing focused BDD tests for each implemented module, or explicit blockers.
- Implementation reports as PR descriptions when a remote/PR flow exists, otherwise under `<output_repo>/implementation-reports`.

Human gates: once all modules at a bottom-up level are complete, present their implementation reports together before ascending. Resolve any decisions made on underspecified cases before continuing.

## Completion response

When all phases are complete, respond with "Migration workflow complete" and name the key artifact locations, spec/test locations, implementation report locations, and final test status.

If blocked, respond with the smallest set of questions or decisions needed to continue, grouped by phase and module where applicable.
