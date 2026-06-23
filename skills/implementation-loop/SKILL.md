---
name: implementation-loop
description: Protocol for implementing a migration plan bottom-up, with a worker-reviewer iteration loop per module and human approval gates before ascending each level of the plan tree.
---

# Implementation Loop

## When to use

Use this skill after the BDD review loop is complete — BDD specs are approved and tests are written for all modules. Implement the plan tree bottom-up, starting from leaves and ascending to integration nodes and root entry points.

## Input

- **Requirements document**: requirements.md — the approved migration goal, target language and stack, architectural requirements, behavioral policy, user base, and known constraints. Read this before implementing any module. It is the big-picture authority: when a plan entry is silent on a decision, requirements.md is the first place to look for constraints. The reviewer uses it to check that implementation choices and any scope expansions stay within approved boundaries.
- **Migration plan**: approved plan file, typically `<artifact_dir>/plan.md` — module entries with interface contracts, `node_type` (leaf/integration), `dependency_interfaces`, acceptance criteria, parallel/sequential markers, and open questions.
- **Specs and tests**: for leaf nodes, approved interface contract specs (`.md`) under specs/ and unit tests in the target repository's test directory; for integration/entry-point nodes, approved Gherkin feature files (`.feature`) under specs/, BDD test definitions, and integration tests in the target repository's test directory. Both the spec surface and the unit/integration surface are acceptance mechanisms. All produced by the BDD review loop.
- **Characterization report**: characterization-report.md — legacy behavior oracle. Use when the implementation of a module is ambiguous and the legacy behavior is the reference.
- **Characterization tests**: characterization tests written by the `discovery` loop that demonstrate behavior of the source system. Usually found alongside characterization-report.md or documented therein.

## Details

### Traversal order: bottom-up BFS

Start at the leaves of the plan tree — modules with no in-migration dependencies. Once a level's modules are complete (tests passing, reviewer satisfied, human approved), ascend to the next level. Integration nodes may not begin until all their dependencies are complete.

Modules marked **independent** at the same level can be worked in parallel using worktree isolation. Ask the human before employing parallelization.

### Per-module loop

For each module:

1. **Worker implements** — the worker agent (or the nearest available equivalent to a 'worker' agent) implements the module against its interface contract and acceptance criteria. If the target repository is under version control, create a new branch for each module implementatoin and work on this. Always start from the 'main' or 'master' branch. The agent reads the module's plan entry (including `node_type` and `dependency_interfaces`), the parent meta-issue entry for shared interface context, the module's BDD spec, and the unit/integration test file produced in the BDD review loop. Take into account fundamental dependencies that shape subsystem behavior, e.g., torch for machine learning, Eigen3 for C++ numerics, or sqlite3 for database modules.
2. **Run BDD tests and unit/integration tests** — run both test sets for this module only. Do not run the full suite. For leaf nodes: run BDD step definitions and the unit test file. For integration nodes: run BDD step definitions and the integration test file. If either test set fails, return to the worker immediately without proceeding to review.
3. **Check equivalence to characterization tests** - check the characterization tests of the source system, and identify if the currently worked on module defines outputs that should be equivalent to the observed behavior of the legacy system. Check that this equivalence is given, using the structure and existing 'golden files' of the characterization tests. If the level of desired equivalence is unclear, ask the human reviewer. If the desired level of equivalence is not given, return to the worker and iterate in this way until it is.
4. **Review** — once both test sets pass, invoke the reviewer agent with the implementation, test files, plan entry, BDD spec, test results, and characterization findings and -tests. The reviewer works through four concerns in sequence, producing a finding list and a verdict of `blocking`, `advisory`, or `clear` for each:
   - **Correctness** — is the logic correct for all cases in the acceptance criteria? Are edge cases, error paths, boundary conditions, and numerical/data contracts handled? Cross-check against the characterization oracle where the legacy behavior is the reference. Treat the characterization tests as part of the acceptance criteria.
   - **Test quality** — do the BDD step definitions and unit/integration tests actually exercise the claimed behavior, or do any pass trivially? Are assertions precise enough to distinguish a correct implementation from a wrong one? Is scenario coverage complete relative to the approved spec?
   - **Unnecessary complexity** — is the implementation as simple as the specified behavior requires? Flag over-engineering, premature abstraction, unused generality, or complexity that will make integration harder. Do not flag necessary complexity required by a `dependency_interface` contract.
   - **Spec conformance** — does the implementation match the approved BDD spec, the plan's interface contract, and every `dependency_interface`? Flag silent scope expansion, missing scenario coverage, interface deviations, or dependency protocol violations.

5. **Iterate** — if any concern has a `blocking` finding, return the module to the worker with the full reviewer output. Loop steps 1–3 until all four concerns are `clear` or `advisory` and both test sets pass. If the target repository is under version control, create a new commit for each iteration step.
6. **Write implementation report** — once the loop exits cleanly, produce the implementation report for this module (see below). If the target is under version control, commit the implementation report, review report and created code into the repository.

### Acceptance criteria

The acceptance criteria live in the module's plan entry. Each reviewer's mandate is limited to their concern and to those criteria — no reviewer may expand scope or impose requirements beyond what the plan specifies. Out-of-scope concerns are flagged `advisory` in the report for the human to decide, not treated as blocking.

A module is accepted when:
- Both test sets pass (BDD step definitions and unit tests for leaf nodes, or integration tests for integration nodes).
- All four reviewer concerns return `clear` or `advisory` — no `blocking` findings remain.
- All `dependency_interfaces` listed in the plan entry are confirmed satisfied — this falls under the spec-conformance concern and must be checked explicitly, not assumed from test passage.
- The observed module behavior is equivalent to the behavior observed via the characterization tests for the corresponding functionality in the source repository based on the `golden file` pattern used in the charachterization-methodology skill, if such a correspondence exists for this module.

### Handling underspecified cases

The worker may encounter gaps the plan did not resolve. The worker is permitted to make implementation choices to fill these gaps, subject to two constraints:

- The choice must not violate the module's interface contract, its `dependency_interfaces`, or another module's acceptance criteria.
- Every choice made must be recorded in the implementation report, with a brief rationale.

Choices that could affect another module's interface, the overall data flow, or a dependency interface contract must be flagged explicitly in the report as **decisions requiring human confirmation** and presented at the human gate before ascending. Dependency interface choices are a specific high-risk category: a wrong choice here can cascade across multiple modules or require architectural changes.

### Human gate

After all modules at a level are complete, present their implementation reports together to the human via contact_supervisor.

The human reviews and either:

- **Approves** — commit each approved module's changes, then ascend to the next level.
- **Requests changes** — the affected module loops back to the worker without committing. Do not begin the next level until all are approved and committed.

Decisions flagged as requiring human confirmation must be resolved at this gate before ascending.

### Implementation report

Write one implementation report per module. If the target repository has a remote, create a new pull request/merge request or equiavlent object and write the report as the PR description for that module's branch. Otherwise write it to implementation-reports/<module-name>.md. In case of an available version control remote, create a single PR per module.

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

- Implemented modules in the target language, one per plan entry, passing both their BDD tests and their unit tests (leaf nodes) or integration tests (integration nodes), and, if applicable, the equivalence check with the corresponding characterization test.
- Implementation reports per module, in a PR or implementation-reports/, each including BDD test results, unit/integration test results, and dependency interface compliance verification.
- A fully implemented, test-passing migration on completion of the root level.


