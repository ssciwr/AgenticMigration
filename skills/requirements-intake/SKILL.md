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

## Review checklist

### Scope

What kind of system is this?

Examples: scientific or research code, general service or application, teaching
or demonstration tool, internal tooling, data pipeline, CLI tool.

If not stated, ask.

### User base

Who will use the resulting system?

Examples: domain specialist (scientist, engineer), learner or student,
non-specialist with domain knowledge, generic end user, developer or API consumer.

If not stated, ask.

### Architectural requirements

How should the system be structured?

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

If not stated, ask.

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

For each missing item: ask a specific, direct question. Do not guess or infer.

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

## Open questions

<items the human has accepted as unresolved at this stage>
```

Do not invent content other than where you are explicitly allowed to fill in the blanks.
Flag any choices you made explicitly.
