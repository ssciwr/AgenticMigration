---
name: bdd-review-loop
description: Protocol for writing BDD specs and tests for a migration plan using breadth-first traversal of the plan tree, with human review gates at each level.
---

# BDD Review Loop

## When to use

Use this skill when you have an approved migration plan (plan/ directory) and need to produce BDD specifications and executable tests for each module. Apply it after the discovery phase and human approval of the migration plan.

## Input

- **Migration plan**: the plan/ directory — the central artifact throughout this skill. Contains meta-issue and module entries that define the tree structure, interface contracts, and module boundaries.
- **Requirements document**: requirements.md — approved migration goal, behavioral requirements, and constraints. Use to stay aligned with approved scope.
- **Characterization report**: characterization-report.md — observed legacy behavior, decision candidates, and behavior inventory. Use as context when writing specs for modules that map to legacy behavior.

Read all three before beginning any spec work.

## Details

### Reconstructing the plan tree

Read all files under plan/ before starting. Meta-issue files list their sub-modules; leaf module files have no sub-modules. Reconstruct the parent→child relationships from these entries.

Identify root nodes — modules with no parent, or the top-level entry points listed in requirements. These are level 0. Their direct children are level 1, and so on. A flat list of independent modules with no parent/child structure is a single-level tree; process them all at level 0.

### Traversal order: breadth-first

Process all modules at level N before descending to level N+1. Siblings at the same level share an abstraction boundary — specifying them together surfaces interface incompatibilities before you invest in specifying their children. Depth-first would let one branch reach full detail before problems in a sibling's interface are caught.

Do not begin level N+1 until all level-N specs are approved and tests are written.

### Per-level protocol

For each level:

1. **Surface open questions first** — if any module at this level has open questions in its plan entry that affect the interface contract, present them to the human via contact_supervisor before writing any specs for this level. Do not write specs for a module with unresolved interface questions.

2. **Write specs** — invoke bdd-spec-writer for each module at this level. Siblings are independent and can be worked in parallel.

3. **Human gate** — present all sibling specs together for review via contact_supervisor. The human should review the full sibling set together: reviewing siblings as a group catches interface incompatibilities between them that per-module review would miss.

4. **Revise if needed** — if the human requests revisions, revise and re-present only the affected specs. Specs already approved are held; do not re-present them.

5. **Write tests** — once all sibling specs at this level are approved, invoke bdd-test-writer for each. Siblings can be worked in parallel. Do not begin test writing for any module until its spec is approved.

6. **Descend** — once all modules at this level have approved specs and written tests, proceed to the next level.

### Partial approvals

If the human approves some siblings but requests revisions on others:
- Approved siblings proceed to test writing immediately.
- Revised siblings loop back to step 2 for that module only.
- Do not hold approved siblings waiting for revised ones to catch up.
- Do not descend to the next level until every sibling at the current level has an approved spec and written tests.

### Scoping context for spec writing

When invoking bdd-spec-writer for a module, provide:
- the module's own plan entry (what it does, interface contracts, characterization findings, open questions, BDD handoff context),
- the parent meta-issue entry if one exists (shared data formats, interface contracts that apply across siblings),
- characterization findings referenced in the module entry,
- requirements sections relevant to this module's scope.

Do not pass the full plan tree or full characterization report — scope the context to the module being specified. Over-broad context dilutes the spec writer's focus.

### Spec and test placement

Write BDD specs under specs/ in the target repository, one file per module, named after the module (e.g. specs/file-reader.md).

For tests, follow the project's existing test structure. If none exists, create tests/ at the project root and place test files adjacent to the modules they cover, following the target language's conventions.

## Output

- BDD specs under specs/, one per module, at each level after human approval.
- Executable tests implementing the approved specs, placed according to the project's test structure.
- All modules in the plan tree covered before the skill is complete.
