---
name: requirements-intake
description: >
  Reviews incoming migration or refactor requirements for completeness before
  planning begins. Checks scope, user base, architectural requirements, behavioral
  requirements, dependencies, and output repository setup. Asks the human clarifying
  questions for missing or ambiguous items, then writes an approved requirements.md.
---

# Requirements Intake

## Purpose

Review incoming requirements for a migration, refactor, or rewrite before any
planning or implementation begins.

The goal is not to produce or infer requirements. The goal is to identify what
is present, what is missing, and what is ambiguous — then ask the human to fill
the gaps.

Do not proceed to planning until the human has approved the requirements.

## Required inputs

Before asking the human any questions, read and internalize these artifacts:

- **Characterization report** (`characterization-report.md`): current observable
  behavior of the legacy system, including discovered entry points, data formats,
  numerical tolerances, error behavior, and decision candidates flagged for human
  resolution.
- **Repository overview** (`scout/overview.html`): module structure, tech stack,
  architecture, entry points, and existing tests.
- **Any existing documentation** in the repository (README, docs/).

Do not ask the human about anything these artifacts already answer clearly.
Only ask when the artifacts are silent, ambiguous, or contradictory on a point.
When asking, cite the relevant finding to give the human context.

## Review checklist

### Scope

What kind of system is this?

Examples: scientific or research code, general service or application, teaching
or demonstration tool, internal tooling, data pipeline, CLI tool.

Check the repository overview's module descriptions and README for clues before
asking. If not determinable from those artifacts, ask.

### User base

Who will use the resulting system?

Examples: domain specialist (scientist, engineer), learner or student,
non-specialist with domain knowledge, generic end user, developer or API consumer.

If not stated, ask.

### Architectural requirements

How should the system be structured?

Check the characterization report for constraints that limit architectural
choices — for example: numerical tolerances that must be preserved, file formats
that are part of the public contract, or global state that existing callers
depend on. Surface these to the human as constraints, not assumptions.

If not provided by the human, apply these defaults and make them explicit in the output:

- **SOLID principles**: single responsibility, open/closed, Liskov substitution,
  interface segregation, dependency inversion.
- **Clean hot-path**: keep the performance-critical path free of orchestration, logging and control-flow logic as far as possible.
- **Decisions at the highest level possible**: policy and configuration choices
  belong at the top of the call stack, not buried in low-level routines.
- **Separation of parameterization and code**: constants, thresholds, and
  configuration must not be hardcoded into logic.
- **Separation of hot-path and orchestration**: the main computation and the
  control flow around it are distinct layers.

State that you used these in the output file.

If the human provides architectural requirements that override or extend these
defaults, use theirs. If a provided requirement conflicts with a default, use the human's
requirements, but flag the conflict so they can revise their requirments if needed.

### Behavioral requirements

How should the system behave from the outside?

- What are the intended entry points? (CLI, importable library, REST API, GUI, other)
- Should it be delivered as a library, an application, or both?
- Are there specific interfaces that must remain stable across the migration?
- Are there interfaces that must change?

Use the repository overview's entry points and the characterization report's
observed API surface as a starting point. Present what was found and ask the
human to confirm, extend, or override — do not ask them to describe from scratch
what the artifacts already show.

### Dependencies

What external dependencies are expected or required?

Ask about each of the following categories that may be relevant:

- **User interface**: is a GUI needed? If so, what framework is expected?
- **Numerical or ML framework**: is there a preferred computation backend?
  (e.g. JAX, PyTorch, TensorFlow, or equivalents in other languages)
- **Data handling**: how is data read, written, and passed between components?
  (e.g. file-based, in-memory, database, streaming, specific formats)
- **Other significant dependencies**: any external service, protocol, or library
  the system must integrate with.

Use the repository overview's tech stack section as a starting point. Present
what was found and ask the human to confirm or override rather than asking them
to list dependencies from scratch.

Do not prescribe specific tools. Ask which category of dependency is needed and
let the human name the tool. If a category is not relevant, skip it. If the human
states some category, but does not know the tool, infer a modern and suitable one,
and state in the output file succinctly why you chose it and for what.

### Output repository

Where and how should the new code live?

Ask:

- Should a new repository be created, or does one already exist?
- What is the expected project structure? (library package, application, monorepo, other)
- What build or package management approach is expected?

Keep this high-level. Do not prescribe specific tools. If the human is unsure,
record it as an open question rather than deciding for them.

## How to handle missing or ambiguous items

Before asking the human anything, check whether the characterization report or
repository overview already answers the question. If they do, use that answer
and note the source. If they are ambiguous or silent, ask.

For each missing item: ask a specific, direct question. Cite the relevant
artifact finding where it helps frame the question — for example: "the
characterization report shows the solver currently writes output to stdout in
fixed-width format — should this format be preserved in the new system?"

For each ambiguous item: quote the ambiguous text and ask what it means.

Batch related questions where possible to avoid overwhelming the human with
one question at a time. Group them by checklist category.

Do not proceed to writing `requirements.md` until the human has confirmed the
requirements are complete or has explicitly accepted remaining gaps as open questions.

## Output: READY or NOT READY

After reviewing, return one of:

```
READY
```

or:

```
NOT READY

Missing:
- <category>: <specific question for the human>

Ambiguous:
- <category>: "<quoted text>" — <what is unclear>

Defaults applied (confirm or override):
- <architectural default that was assumed>
```

## Writing requirements.md

Once the human approves, write `requirements.md` into the root of the output
repository, or into the current working directory if the repository does not
exist yet.

Use this structure:

```markdown
# Requirements: <project name>

## Scope

<what kind of system this is and its purpose>

## User base

<who will use the system and what expertise they bring>

## Architectural requirements

<stated requirements; defaults listed with a note that they are defaults>

## Behavioral requirements

### Entry points

<intended entry points>

### Delivery

<library, application, or both>

### Interface stability

<what must remain stable; what is expected to change>

## Dependencies

<expected external dependencies, listed by category>

## Output repository

<repository setup, project structure, build approach>

## Characterization findings carried forward

<behaviors from the characterization report the human has explicitly decided to
preserve, change, or remove. Format as a table:>

| Behavior | Decision | Notes |
| --- | --- | --- |
| <observed behavior> | preserve / change / remove | <rationale if given> |

## Open questions

<items the human has accepted as unresolved at this stage>
```

Do not invent content other than where you are explicitly allowed to fill in the blanks.
Flag any choices you made explicitly.
