---
description: Full agentic migration workflow — from legacy codebase to migrated implementation.
---

# Migration Workflow

This workflow migrates a legacy codebase to a target language and stack. It proceeds in three
phases, each gated by human approval before the next begins.

## Phase 1 — Discovery

Run the discovery chain:

```
/run-chain discovery -- /path/to/legacy/repo
```

This characterizes the legacy codebase, generates a repository overview, gathers and validates
requirements, produces a migration plan, and has an oracle review the plan for gaps.

**Human gate**: review the plan at `<artifact_dir>/plan.md` and the oracle's concerns before proceeding.
Resolve any open questions flagged in the plan entries. Approve or request revisions.

## Phase 2 — BDD specs and tests

Apply the bdd-review-loop skill to the approved plan:

```
Apply the bdd-review-loop skill to the repository at /path/to/legacy/repo.
```

This traverses the plan tree breadth-first, writing BDD specs and tests level by level.

**Human gates**: after all sibling specs at each level are written, they are presented
together for review — siblings share an abstraction boundary and must be approved as a
group. Tests are written only after approval. This repeats for every level of the plan tree.

## Phase 3 — Implementation

Apply the implementation-loop skill:

```
Apply the implementation-loop skill to the repository at /path/to/legacy/repo.
```

This traverses the plan tree bottom-up. For each module, the worker implements and iterates
with the reviewer until BDD tests pass and no blocking issues remain.

**Human gates**: once all siblings at a level are complete (tests passing, reviewer satisfied),
their implementation reports are presented together for review before ascending to the next
level. Any decisions made on underspecified cases are flagged explicitly at this gate.
Implementation reports go to PR descriptions if a remote exists, otherwise to
implementation-reports/ in the target repository.
