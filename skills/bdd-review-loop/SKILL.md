---
name: bdd-review-loop
description: Protocol for writing BDD specs and tests for a migration plan using breadth-first traversal of the plan tree, with human review gates at each level.
---

# BDD Review Loop

## When to use

Use this skill when you have an approved migration plan file, typically `<artifact_dir>/plan.md`, and need to produce BDD specifications and executable tests for each module. Apply it after the discovery phase and human approval of the migration plan.

## Input

- **Migration plan**: the approved plan file, typically `<artifact_dir>/plan.md` — the central artifact throughout this skill. It defines the tree structure, interface contracts, `node_type` (leaf/integration), `dependency_interfaces`, module boundaries, acceptance criteria, parallel/sequential markers, and open questions.
- **Requirements document**: requirements.md — approved migration goal, behavioral requirements, and constraints. Use to stay aligned with approved scope.
- **Characterization report**: characterization-report.md — observed legacy behavior, decision candidates, and behavior inventory. Use as context when writing specs for modules that map to legacy behavior.

Read all three before beginning any spec work.

Before beginning any level, verify that every module in the plan has `node_type` and `dependency_interfaces` fields. If any module is missing either field, surface this as a blocking question to the human — do not write specs for modules with unresolved dependency interfaces.

## Details

### Reconstructing the plan tree

Read the full approved plan file before starting. Reconstruct the parent→child relationships from the plan's dependency tree and module entries. If a legacy plan directory is supplied instead, read all files under it, but do not require a `plan/` directory when `<artifact_dir>/plan.md` is available.

Identify root nodes — modules with no parent, or the top-level entry points listed in requirements. These are level 0. Their direct children are level 1, and so on. A flat list of independent modules with no parent/child structure is a single-level tree; process them all at level 0.

### Traversal order: breadth-first

Process all modules at level N before descending to level N+1. Siblings at the same level share an abstraction boundary — specifying them together surfaces interface incompatibilities before you invest in specifying their children. Depth-first would let one branch reach full detail before problems in a sibling's interface are caught.

Do not begin level N+1 until all level-N specs are approved and tests are written.

### Per-level protocol

For each level:

1. **Surface open questions first** — if any module at this level has open questions in its plan entry that affect the interface contract, or has missing/unresolved `dependency_interfaces`, present them to the human via contact_supervisor before writing any specs for this level. Do not write specs for a module with unresolved interface or dependency interface questions.

2. **Write specs** — invoke bdd-spec-writer for each module at this level. Siblings are independent and can be worked in parallel.

3. **Human gate** — present all sibling specs together for review via contact_supervisor. The human should review the full sibling set together: reviewing siblings as a group catches interface incompatibilities between them that per-module review would miss. Explicitly confirm that all `dependency_interfaces` entries for this level have corresponding scenario coverage in the specs.

4. **Revise if needed** — if the human requests revisions, revise and re-present only the affected specs. Specs already approved are held; do not re-present them.

5. **Write tests** — once all sibling specs at this level are approved, invoke bdd-test-writer for each. Siblings can be worked in parallel. Do not begin test writing for any module until its spec is approved. For each module, bdd-test-writer must produce the dual test surface: BDD step definitions plus unit tests (leaf nodes) or integration tests (integration nodes). Confirm both artifacts are present before marking a module's tests complete.

6. **Descend** — once all modules at this level have approved specs and written tests, proceed to the next level.

### Partial approvals

If the human approves some siblings but requests revisions on others:
- Approved siblings proceed to test writing immediately.
- Revised siblings loop back to step 2 for that module only.
- Do not hold approved siblings waiting for revised ones to catch up.
- Do not descend to the next level until every sibling at the current level has an approved spec and written tests.

### Scoping context for spec writing

When invoking bdd-spec-writer for a module, provide:
- the module's own plan entry (what it does, `node_type`, `dependency_interfaces`, interface contracts, characterization findings, open questions, BDD handoff context),
- the parent meta-issue entry if one exists (shared data formats, interface contracts that apply across siblings),
- characterization findings referenced in the module entry,
- requirements sections relevant to this module's scope.

Do not pass the full plan tree or full characterization report — scope the context to the module being specified. Over-broad context dilutes the spec writer's focus.

When invoking bdd-test-writer for a module, additionally provide:
- the module's approved BDD specification including its `Dependency interface coverage` and `Test implementation notes` sections,
- the module's `node_type` and `dependency_interfaces` from the plan entry,
- the target language and any approved test framework choices made earlier in the workflow.

### BDD framework and package setup

Before converting approved specs into executable tests, identify whether the target language has a viable BDD framework for Gherkin-style feature execution. Prefer using that framework over hand-written tests that merely approximate the scenarios.

Examples:
- Julia: use `Behavior.jl` where viable. Add it to the target package/test dependencies, keep `.feature` files as executable specs, place step definitions in the framework's expected step directory or configure the runner explicitly, and wire the package test command to run approved feature files.
- Python: use `pytest-bdd` or `behave` where viable, with feature files and step definitions wired into the package test command.

If no viable BDD runner exists, fall back to ordinary unit/integration tests, but preserve traceability to feature and scenario names.

When a BDD framework is selected, package setup is part of this workflow: add the required test dependencies and test runner configuration before or alongside executable test writing. This setup must not implement production domain behavior.

### Spec and test placement

Write BDD specs as `.feature` files under specs/ in the target repository, one file per module, named after the module (e.g. specs/file-reader.feature), unless the human supplies a different `spec_dir` or the selected BDD framework requires a conventional feature directory. If framework convention differs from `specs/`, either configure the framework to read `specs/` or document the executable feature directory clearly.

For tests, follow the project's existing test structure and the selected BDD framework's conventions. Place step definitions, glue code, and runner configuration under the target repository's test structure unless the framework requires a different location.

## Output

- BDD specs under specs/, one per module, at each level after human approval. Each spec includes a `Dependency interface coverage` section accounting for all `dependency_interfaces` in the plan entry.
- For each module: BDD step definitions/runner glue implementing the approved feature file, plus a separate unit test file (leaf nodes) or integration test file (integration nodes) covering interface contracts and dependency interface compliance.
- All modules in the plan tree covered before the skill is complete.
