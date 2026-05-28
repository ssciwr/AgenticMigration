---
name: implementation-loop
description: Protocol for implementing a migration plan bottom-up, with a worker-reviewer iteration loop per module and human approval gates before ascending each level of the plan tree.
---

# Implementation Loop

## When to use

Use this skill after the BDD review loop is complete — BDD specs are approved and tests are written for all modules. Implement the plan tree bottom-up, starting from leaves and ascending to integration nodes and root entry points.

## Input

- **Migration plan**: approved plan file, typically `<artifact_dir>/plan.md` — module entries with interface contracts, `node_type` (leaf/integration), `dependency_interfaces`, acceptance criteria, parallel/sequential markers, and open questions.
- **BDD specs and tests**: approved `.feature` files under specs/, BDD step definitions, and the dual test surface (unit tests for leaf nodes, integration tests for integration nodes) produced by the BDD review loop. Both the BDD surface and the unit/integration surface are acceptance mechanisms.
- **Characterization report**: characterization-report.md — legacy behavior oracle. Use when the implementation of a module is ambiguous and the legacy behavior is the reference.

## Details

### Traversal order: bottom-up BFS

Start at the leaves of the plan tree — modules with no in-migration dependencies. Once a level's modules are complete (tests passing, reviewer satisfied, human approved), ascend to the next level. Integration nodes may not begin until all their dependencies are complete.

Modules marked **independent** at the same level can be worked in parallel using worktree isolation. Ask the human before employing parallelization.

### Per-module loop

For each module:

1. **Worker implements** — the worker agent implements the module against its interface contract and acceptance criteria. It reads the module's plan entry (including `node_type` and `dependency_interfaces`), the parent meta-issue entry for shared interface context, the module's BDD spec, and the unit/integration test file produced in the BDD review loop. Take into account fundamental dependencies that shape subsystem behavior, e.g., torch for machine learning, Eigen3 for C++ numerics, or sqlite3 for database modules.
2. **Run BDD tests and unit/integration tests** — run both test sets for this module only. Do not run the full suite. For leaf nodes: run BDD step definitions and the unit test file. For integration nodes: run BDD step definitions and the integration test file. If either test set fails, return to the worker immediately without proceeding to review.
3. **Parallel review** — once both test sets pass, run four focused reviewers simultaneously. Each reviewer receives the same inputs (implementation, test files, plan entry, BDD spec, test results, characterization findings) but is scoped to exactly one concern. Each produces a finding list and a verdict of `blocking`, `advisory`, or `clear` for their concern only.

   - **Correctness** — is the logic correct for all cases in the acceptance criteria? Are edge cases, error paths, boundary conditions, and numerical/data contracts handled? Cross-check against the characterization oracle where the legacy behavior is the reference.
   - **Test quality** — do the BDD step definitions and unit/integration tests actually exercise the claimed behavior, or do any pass trivially? Are assertions precise enough to distinguish a correct implementation from a wrong one? Is scenario coverage complete relative to the approved spec?
   - **Unnecessary complexity** — is the implementation as simple as the specified behavior requires? Flag over-engineering, premature abstraction, unused generality, or complexity that will make integration harder. Do not flag necessary complexity required by a `dependency_interface` contract.
   - **Spec conformance** — does the implementation match the approved BDD spec, the plan's interface contract, and every `dependency_interface`? Flag silent scope expansion, missing scenario coverage, interface deviations, or dependency protocol violations.

4. **Aggregate findings** — collect all four reviewer outputs. A module may advance only when every reviewer returns `clear` or `advisory`. Any `blocking` verdict from any reviewer sends the module back to the worker with that reviewer's specific, actionable feedback. Multiple blocking findings may be batched into one worker pass. Advisory findings do not block advancement but are included in the implementation report.
5. **Iterate** — loop steps 1–4 until all four reviewers return `clear` or `advisory` and both test sets pass. Each iteration should address only the feedback from the previous round's blocking reviewers; do not re-run reviewers that already returned `clear`.
6. **Write implementation report** — once the loop exits cleanly, produce the implementation report for this module (see below).

### Acceptance criteria

The acceptance criteria live in the module's plan entry. Each reviewer's mandate is limited to their concern and to those criteria — no reviewer may expand scope or impose requirements beyond what the plan specifies. Out-of-scope concerns are flagged `advisory` in the report for the human to decide, not treated as blocking.

A module is accepted when:
- Both test sets pass (BDD step definitions and unit tests for leaf nodes, or integration tests for integration nodes).
- All four parallel reviewers return `clear` or `advisory` — no `blocking` findings remain.
- All `dependency_interfaces` listed in the plan entry are confirmed satisfied — this falls under the spec-conformance reviewer's mandate and must be checked explicitly, not assumed from test passage.

### Handling underspecified cases

The worker may encounter gaps the plan did not resolve. The worker is permitted to make implementation choices to fill these gaps, subject to two constraints:

- The choice must not violate the module's interface contract, its `dependency_interfaces`, or another module's acceptance criteria.
- Every choice made must be recorded in the implementation report, with a brief rationale.

Choices that could affect another module's interface, the overall data flow, or a dependency interface contract must be flagged explicitly in the report as **decisions requiring human confirmation** and presented at the human gate before ascending. Dependency interface choices are a specific high-risk category: a wrong choice here can cascade across multiple modules or require architectural changes.

### Human gate

After all modules at a level are complete, present their implementation reports together to the human via contact_supervisor. The human reviews and either:

- **Approves** — work ascends to the next level.
- **Requests changes** — the affected module loops back to the worker. Modules not under revision are held; do not begin the next level until all are approved.

Decisions flagged as requiring human confirmation must be resolved at this gate before ascending.

### Implementation report

Write one implementation report per module. If the target repository has a remote, write it as the PR description for that module's branch. Otherwise write it to implementation-reports/<module-name>.md.

Each report covers:
- what was implemented and against which acceptance criteria,
- BDD test results,
- unit test results (leaf nodes) or integration test results (integration nodes),
- dependency interface compliance: for each `dependency_interface` in the plan entry, state whether it is satisfied and how it was verified,
- parallel review summary: for each of the four reviewers (correctness, test quality, complexity, spec conformance), state the final verdict (`clear` / `advisory`) and list any advisory findings for the human's awareness,
- decisions made on underspecified cases (with rationale),
- decisions requiring human confirmation (if any),
- deviations from the plan entry, if any, and why.

Keep it factual and brief. It is a handoff document for the human gate, not a design document.

## Output

- Implemented modules in the target language, one per plan entry, passing both their BDD tests and their unit tests (leaf nodes) or integration tests (integration nodes).
- Implementation reports per module, in PRs or implementation-reports/, each including BDD test results, unit/integration test results, and dependency interface compliance verification.
- A fully implemented, test-passing migration on completion of the root level.
