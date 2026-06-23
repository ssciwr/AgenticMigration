---
name: bdd-review-loop
description: Protocol for writing BDD specs and tests for a migration plan using breadth-first traversal of the plan tree, with human review gates at each level.
---

# BDD Review Loop

## When to use

Use this skill when you have an approved migration plan file, typically `<artifact_dir>/plan.md`, and need to produce human-approved specifications and executable tests for each module. Apply it after the discovery phase and human approval of the migration plan.

## Purpose

This skill defines an **intent-engineering workflow** that makes the users's intent testable and specific. Its job is to help a human who may not know the legacy code deeply to discover and declare what they want the migrated system to do, grounded in what the legacy system actually does. The characterization report is the factual foundation; the human's intentions are the goal; the output is an explicit, human-approved specification for each module, fixed in test code and user stories.

The human gate at each level is not a rubber stamp — it is the central purpose. The human is actively deciding: what behavior to preserve, what to change, what to remove, and what interfaces to expose. Until the human has signed off on a module's specification, implementation must not begin.

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
The result is a tree of interdependent tasks for which specifications and tests to check them will be written.

### Specification format by node type

The spec artifact differs by node type. Both formats require explicit human approval before tests are written.

**Leaf nodes** (`node_type: leaf`) — produce an **interface contract specification** (not a Gherkin file):
- The human's intent for this module, in their own terms, grounded in the characterization findings.
- Behavior dispositions for each relevant characterization finding: preserve / intentionally change / remove / still undecided.
- The module's interface: inputs, outputs, error behavior, calling convention, framework protocols (`dependency_interfaces`).
- Acceptance criteria.
- Open questions requiring a human decision before implementation.

The interface contract is the intent artifact the human signs off on. Gherkin is not used at leaf level because the human's intent is better expressed as a typed contract than as a narrative scenario.

**Integration and entry-point nodes** (`node_type: integration`, or root nodes) — produce a **Gherkin feature file**:
- Written in plain language the human can reason about without knowing the code.
- Grounded in the characterization findings and the human's stated intent.
- Each scenario expresses observable behavior the human is explicitly approving.
- Dependency interface compliance scenarios included where relevant.


### Traversal order: breadth-first

Process all modules at level N before descending to level N+1. Siblings at the same level share an abstraction boundary — specifying them together surfaces interface incompatibilities before you invest in specifying their children. Depth-first would let one branch reach full detail before problems in a sibling's interface are caught, so don't do that.
Do not begin level N+1 until all level-N specs are approved and tests are written.

### Per-level protocol

For each level in the task tree:

1. **Surface open questions first** — if any module at this level has open questions in its plan entry that affect the interface contract, or has missing/unresolved `dependency_interfaces`, present them to the human via contact_supervisor (if available), or the approved way of contacting them,before writing any specs for this level. Do not write specs for a module with unresolved interface or dependency interface questions.

2. **Write specs** — invoke bdd-spec-writer for each module at this level, passing the `node_type` so the correct format is produced (interface contract for leaf nodes, Gherkin feature file for integration/entry-point nodes). Siblings are independent and can be worked on in parallel using subagents; ask the human before employing parallelization.

3. **Human gate** — present all sibling specs together for review via contact_supervisor (if available) or the approved way of contacting them. The human reviews the full sibling set together: for integration nodes, confirm scenario coverage and `dependency_interfaces` compliance; for leaf nodes, confirm behavior dispositions and interface contracts match their intent. Reviewing siblings as a group catches incompatibilities between them.

4. **Revise if needed** — if the human requests revisions, revise and re-present only the affected specs. Specs already approved are held; do not re-present them.

6. **Write tests** — once all sibling specs at this level are approved, invoke bdd-test-writer for each. Siblings can be worked in parallel with subagents; ask the human before employing parallelization. Do not begin test writing for any module until its spec is approved.
   - Leaf nodes: unit tests derived from the approved interface contract and behavior dispositions. No BDD runner required.
   - Integration/entry-point nodes: BDD step definitions for the approved feature file, plus integration tests.
   Confirm both test artifacts are present before marking a module's tests complete.

6. **Descend** — once all modules at this level have approved specs and written tests, proceed to the next level.

### Partial approvals

If the human approves some siblings but requests revisions on others:
- Approved siblings proceed to test writing immediately.
- Revised siblings loop back to step 2 for that module only.
- Do not hold approved siblings waiting for revised ones to catch up.
- Do not descend to the next level until every sibling at the current level has an approved spec and written tests.

### Version control usage for bdd specs and interface contract specs
If the target repository is under version control, create a new commit for each level and each revision step with the relevant files included.

### Scoping context for spec writing

When invoking bdd-spec-writer for a module, provide:
- the module's own plan entry (what it does, `node_type`, `dependency_interfaces`, interface contracts, characterization findings, open questions, BDD handoff context),
- the parent's plan entry if one exists (shared data formats, interface contracts that apply across siblings),
- only the characterization findings by ID that the module's plan entry references — extract these from the characterization report rather than passing the full report,
- requirements sections relevant to this module's scope.

Do not pass the full plan tree or full characterization report — scope the context to the module being specified. Over-broad context dilutes the spec writer's focus.

Take into account fundamental dependencies that shape subsystem behavior when scoping context and reviewing dependency interface coverage, e.g., torch for machine learning, Eigen3 for C++ numerics, or sqlite3 for database modules, or QT for GUIs.

When invoking worker for a module, additionally provide:
- the module's approved specification (dependency interface contracts or  bdd specs for leaf nodes and inner nodes respectively) including its `Test implementation notes` sections,
- the module's `node_type` and `dependency_interfaces` from the plan entry,
- the target language and any approved test framework choices made earlier in the workflow.

### BDD framework and package setup

A BDD runner is only needed for integration and entry-point nodes, which have Gherkin feature files from the bdd-spec-writer. Leaf nodes have interface contract specifications and native unit tests — no BDD runner is required for them.

For integration/entry-point nodes, identify whether the target language has a viable BDD framework before writing tests. Prefer using that framework over hand-written tests that merely approximate the scenarios.

Examples:
- Julia: use `Behavior.jl` where viable. Add it to the target package/test dependencies, keep `.feature` files as executable specs, place step definitions in the framework's expected step directory or configure the runner explicitly, and wire the package test command to run approved feature files.
- Python: use `pytest-bdd` or `behave` where viable, with feature files and step definitions wired into the package test command.
- Rust: use for example the `behave` crate.

If no viable BDD runner exists, fall back to ordinary integration tests, but preserve traceability to feature and scenario names.

When a BDD framework is selected, package setup is part of this workflow: add the required test dependencies and test runner configuration before or alongside executable test writing. This setup must not implement production domain behavior.

### Spec and test placement

**Integration/entry-point nodes**: write Gherkin specs as `.feature` files under `specs/` in the target repository, one file per module, named after the module (e.g. `specs/training-loop.feature`), unless the human supplies a different `spec_dir`. Place step definitions and runner configuration in the project's test structure.

**Leaf nodes**: write interface contract specifications as `.md` files under `specs/` (e.g. `specs/graph-conv-layer.md`). Place unit tests in the project's existing test structure following target-language conventions.

### Version control usage for bdd specs and interface contract specs
If the target repository is under version control, create a new commit for the tests written at each level with the relevant files included.

## Output
- **Leaf nodes**: interface contract specification (`.md`) under `specs/`, human-approved; unit tests in the project's test structure.
- **Integration/entry-point nodes**: Gherkin feature file (`.feature`) under `specs/`, human-approved; BDD step definitions plus integration tests in the project's test structure.
- All modules in the plan tree covered, with human approval recorded at each level, before the skill is complete.
