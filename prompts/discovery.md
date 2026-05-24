---
description: Migration discovery workflow prompt — characterize a source repository, gather requirements, and produce a reviewed migration plan for a target language.
---

# Migration Discovery Workflow

Run the discovery phase of a migration without relying on a saved chain. The parent agent remains the orchestrator and delegates individual steps to focused agents as needed.

## Required inputs

Ask for any missing required input before starting.

- `source_repo`: path to the legacy/source repository or subpackage to migrate.
- `output_repo`: path to the future migrated-code repository.
- `target_language`: target implementation language.

## Optional inputs

Ask only when needed for the migration plan or requirements.

- `source_language`: source language if it is not obvious from the repository.
- `target_framework`: preferred framework/runtime/package layout in the target language.
- `artifact_dir`: directory for discovery artifacts. Default: `<output_repo>/discovery`.
- `migration_scope`: whole repository, subpackage, CLI, library API, data pipeline, numerical kernel, UI, or other slice.
- `behavior_policy`: strict behavioral equivalence, equivalent within tolerances, intentional changes allowed, or unknown.
- `performance_policy`: preserve performance, improve performance, not a priority, or unknown.
- `test_policy`: port existing tests, write new tests, keep characterization tests as oracle, or unknown.
- `constraints`: platform, dependency, licensing, deployment, packaging, interface, numerical precision, or data-format constraints.
- `non_goals`: explicitly out-of-scope behavior, modules, or redesigns.

## Invocation template

The human can provide inputs in this shape:

```text
source_repo: /path/to/legacy/repo/or/subpackage
output_repo: /path/to/new/repo
target_language: Rust
target_framework: optional
migration_scope: optional
behavior_policy: optional
constraints: optional
non_goals: optional
```

If `artifact_dir` is not supplied, create and use:

```text
<output_repo>/discovery
```

All discovery artifacts must be written under `artifact_dir`. The `repo-overview` skill writes the primary overview HTML to `<source_repo>/scout/overview.html`; after it is generated, copy that file to `<artifact_dir>/overview.html` — normally `<output_repo>/artifacts/overview.html` when `artifact_dir` is the target repository's artifacts directory — so the discovery workflow can be reconstructed from the target repository artifacts alone.

## Outputs

Produce these durable artifacts:

- `<artifact_dir>/characterization-report.md`
- `<source_repo>/scout/overview.html`
- `<artifact_dir>/overview.html` copied from `<source_repo>/scout/overview.html`
- `<artifact_dir>/overview-summary.md`
- `<artifact_dir>/requirements.md`
- `<artifact_dir>/plan.md` containing the migration plan
- `<artifact_dir>/oracle-review.md

Do not write migrated implementation code during discovery.

## Orchestration rules

- The parent agent owns orchestration, human interaction, and final decisions.
- Use subagents as helpers when available, but do not force the whole workflow through a saved chain.
- Keep write access single-purpose per step: characterization may add tests to the source repository; planning and requirements artifacts go under `artifact_dir`.
- Do not decide target architecture, behavior changes, tolerances, or scope tradeoffs without human approval.
- If a child agent cannot contact the human directly, have it return grouped questions to the parent.
- Prefer evidence from files, tests, docs, and observed behavior over assumptions.
- Treat `target_language` as a first-class requirement and carry it through requirements, plan, BDD preparation, and implementation handoff notes.

## Workflow

### Step 0 — Validate setup and inputs

1. Resolve `source_repo`, `output_repo`, and `artifact_dir` to concrete paths.
2. Confirm `source_repo` exists.
3. Create `artifact_dir` if it does not exist.
4. If `output_repo` does not exist, ask whether to create it now or leave it as a planned destination.
5. Confirm or ask for `target_language` before characterization begins.
6.  Record the accepted inputs at the top of <artifact_dir>/requirements.md when Step 3 begins.

### Step 1 — Characterize existing behavior

Delegate to `characterization-tester` when available.

Task contract:

```text
Characterize the current observable behavior of the source repository at <source_repo>.

Target migration language: <target_language>.
Future output repository: <output_repo>.
Discovery artifact directory: <artifact_dir>.

You are authorized to write characterization tests in the existing test structure of <source_repo>. These tests are the behavioral oracle for the migration. Do not modify production code except when a minimal, clearly reported test harness fixture is unavoidable.

Write golden-file or assertion-based tests that capture current observable behavior. Cover public entry points, data formats, numerical tolerances, error behavior, CLI/API behavior, configuration behavior, and decision candidates. If full coverage is too broad, prioritize externally observable behavior and document gaps.

Write the characterization report to <artifact_dir>/characterization-report.md. Include: observed entry points, commands run, environment assumptions, test files added, golden files added, data formats, numerical tolerances, error behavior, non-determinism, gaps, risks, and decisions requiring human input.
```

Parent validation after the step:

- Confirm `<artifact_dir>/characterization-report.md` exists.
- Confirm any characterization tests were written under `<source_repo>` and are listed in the report.
- If tests could not be written, require explicit evidence and limitations in the report.

### Step 2 — Generate repository overview

Delegate to `scout` with the `repo-overview` skill when available.

Task contract:

```text
Generate a repository overview for <source_repo> using the repo-overview skill.

Write the HTML overview to <source_repo>/scout/overview.html.
Also write a compact text summary to <artifact_dir>/overview-summary.md with: modules, entry points, tech stack, dominant coding/testing paradigms, test layout, data fixtures, documentation pointers, and risks relevant to migration to <target_language>.
```

Parent validation after the step:

- Confirm `<source_repo>/scout/overview.html` exists.
- Copy `<source_repo>/scout/overview.html` to `<artifact_dir>/overview.html` — normally `<output_repo>/artifacts/overview.html`.
- Confirm `<artifact_dir>/overview.html` exists.
- Confirm `<artifact_dir>/overview-summary.md` exists.

### Step 3 — Requirements intake

Apply the `requirements-intake` skill from the parent session, or delegate to `worker` with that skill if desired.

Inputs:

- `<artifact_dir>/characterization-report.md`
- `<artifact_dir>/overview.html`
- `<artifact_dir>/overview-summary.md`
- `source_repo`
- `output_repo`
- `target_language`
- optional inputs supplied by the human

Instructions:

```text
Apply the requirements-intake skill.

Read the characterization report, repository overview, and overview summary before asking questions. Ask only about items not already answered by those artifacts. When asking, cite the specific finding or gap that prompted the question.

The requirements must explicitly cover:
- source repository and migration scope,
- output repository and desired project layout,
- target language and target framework/runtime if any,
- source language and source stack,
- user base and intended usage of the migrated code,
- public APIs, CLIs, file formats, data formats, and compatibility requirements,
- behavioral equivalence policy and numerical tolerances,
- error behavior and edge cases,
- performance expectations,
- dependency, licensing, platform, packaging, and CI constraints,
- testing strategy for characterization tests, BDD tests, and target-language tests,
- non-goals and explicitly deferred work,
- open decisions requiring human approval.

Write the approved requirements to <artifact_dir>/requirements.md. Do not proceed to planning until the human confirms the requirements are complete enough for planning.
```

Human gate:

- Present unresolved questions grouped by category.
- Wait for human answers.
- Update `<artifact_dir>/requirements.md`.
- Ask for explicit approval before planning.

### Step 4 — Migration planning

Apply the `migration-planner` skill from the parent session, or delegate to `planner` with that skill if desired.

Inputs:

- `<artifact_dir>/requirements.md`
- `<artifact_dir>/characterization-report.md`
- `<artifact_dir>/overview.html`
- `<artifact_dir>/overview-summary.md`

Task contract:

```text
Apply the migration-planner skill to produce a structured migration plan from <source_repo> to <target_language> in <output_repo>.

Read requirements, characterization report, overview HTML, and overview summary before planning.

Write the plan as a markdown file at <artifact_dir>/plan.md.

Do not write a root-level <output_repo>/plan.md or a <output_repo>/plan/ directory. If delegating to a subagent, disable automatic subagent output files or set any subagent output path inside <artifact_dir> so the harness does not save an extra plan.md in the output repository root.

The plan must:
- define interface contracts top-down,
- define implementation order bottom-up,
- map legacy modules and entry points to target-language modules,
- specify target repository layout under <output_repo>,
- identify which characterization tests or observed behaviors validate each module,
- identify BDD specs/tests needed for each module,
- specify target-language testing approach and commands where known,
- identify data-format and numerical-tolerance contracts,
- flag unresolved decisions in affected module entries instead of deciding them,
- be self-contained enough for the BDD review loop to work module-by-module.
```

Parent validation after the step:

- Confirm `<artifact_dir>/plan.md` exists and contains the planned out migration.
- Confirm the plan references `target_language` and `output_repo` explicitly.
- Confirm each major source module or behavior has a plan destination or an explicit non-goal/deferred note.

### Step 5 — Oracle review

Delegate to `oracle` when available. This is review-only.

Task contract:

```text
Review the discovery artifacts and migration plan. Do not edit files.

Inputs:
- Requirements: <artifact_dir>/requirements.md
- Characterization report: <artifact_dir>/characterization-report.md
- Overview: <artifact_dir>/overview.html copied from <source_repo>/scout/overview.html
- Overview summary: <artifact_dir>/overview-summary.md
- Plan file: <artifact_dir>/plan.md
- Source repository: <source_repo>
- Output repository: <output_repo>
- Target language: <target_language>

Look for:
- missing modules or unclear/overlapping module scope,
- underdefined interface contracts,
- hidden dependencies in implementation order,
- requirements not reflected in the plan,
- characterization findings or tests not reflected in any plan entry,
- target-language architectural risks,
- output repository layout issues,
- testing gaps,
- alternative decompositions worth raising with the human.

Write a concise review to <artifact_dir>/oracle-review.md. Flag concerns with enough specificity that the human can act on them.
```

Human gate:

- Present the plan location and oracle review location.
- Summarize blockers, decisions needed, and safe-to-defer concerns.
- Do not begin BDD specs or implementation until the human approves the plan or requests revisions.

## Completion response

When discovery is complete, respond with "Codebase discovery complete" and name the artifacts you wrote and where you put them.
If blocked, respond with the smallest set of questions or decisions needed to continue, grouped by category.
