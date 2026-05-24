---
name: migration-planner
description: Methodology to plan out the migration of a codebase from one language to another.
---

# Migration planner

## When to use
Use this skill when you are asked to plan out the migration path of a codebase in one language, paradigm or tech stack to another.
You inspect the input artifacts: characterization tests or summary thereof, gherkin behavior specs and tests, and the requirements file
obtained from the user. Treat the supplied BDD tests as the verification layer, the characterization tests as an oracle, and the requirements file as specifying the goal. Then understand the codebase, and plan out a migration path to the user-specified traget language and -codebase.
Split this migration plan into a set of steps ("modules") which are internally comprised of a set of appropriate substeps. Specify these modules such that are as independent as possible. You also plan out the interfaces that connect these modules. Also plan out the user facing API, any required data handling systems and the data flow that ties the modules together and to the API and data handling systems explicitly. Typically, this implementation plan will take the form of a tree with leafs being individual modules, which are integrated by interfaces into higher order modules and so on until you end up with root nodes that define user facing entry points.
## Input

Expect three input artifacts. Read all three before planning anything.

- **Approved requirements document**: specifies the migration goal, target language and stack, architectural requirements, behavioral requirements, user base, and known constraints.
- **Characterization report**: describes the observed behavior of the legacy system — entry points, data formats, numerical tolerances, error behavior, decision candidates, and behavior inventory.
- **Repository overview**: describes the structure of the legacy codebase — module diagram, class diagram, entry points, tech stack, existing tests, and open questions.

## Details

### Plan structure

Structure the migration plan as a dependency tree. The exact shape depends on the codebase, but the principle is consistent: modules with no dependencies on other migration work are implemented first; modules that compose or integrate others come after; user-facing entry points come last.

The key constraint is that the implementation sequence must respect dependencies — a module cannot be built before the interfaces it depends on are defined and stable.

### Interface definition: top-down first

Before specifying any module's internals, define the interface contracts between modules. Work top-down from the user-facing entry points inward: what must the top level expose, and therefore what must each layer beneath it provide?

An interface contract should be specific enough that a module can be implemented against it without needing to know anything about how the other side works internally. At minimum it should cover what goes in, what comes out, and what failure modes are possible.

Define interfaces before planning module internals. A module planned without a known interface contract risks implementing the wrong surface and requiring rework when integration begins.

### Implementation order: bottom-up

Once interfaces are defined top-down, plan the implementation sequence bottom-up: modules with no in-migration dependencies first, integration and composition layers after. This ensures that by the time a higher-level module is implemented, its dependencies have stable, tested interfaces to build against.

### Module granularity

A module is the right size when:

- it maps to a coherent set of behaviors a domain expert can approve as a unit,
- it can be handed off to the BDD-review-loop as a single self-contained task,
- its interface can be described in a short, unambiguous contract.

Split a module if it contains behaviors belonging to fundamentally different concerns, or if its interface contract is too broad to specify clearly. Merge modules if they are too fine-grained to produce meaningful BDD scenarios independently.

### Parallel and sequential boundaries

Mark each module explicitly as one of:

- **Independent** — no dependency on another in-progress migration module. Safe to implement in parallel using worktree isolation.
- **Sequential** — depends on another module's interface being stable first. List the specific blocking dependency by name.

Do not mark a module as independent if it shares a mutable interface or data format with a concurrently developed module.

### Data flow

Plan data flow explicitly alongside the module tree:

- Identify what data moves between modules and in what format at each boundary.
- Identify where serialization, deserialization, or format conversion occurs and assign it to a specific module.
- Data handling systems (storage, I/O, serialization) are typically leaf modules or dedicated integration modules — plan them explicitly, do not leave them implicit.

### Handling ambiguity and risk

Flag rather than decide when:

- the characterization report contains `unknown` or `inferred` findings that affect a module boundary,
- requirements are ambiguous about a module's scope or interface,
- a decision candidate from the characterization report is unresolved and relevant to the plan.

Record each flag as an open question in the affected module entry. Do not invent requirements to fill gaps.

### Module entry contents

Each module entry must give the BDD-review-loop enough context to write specifications for that module independently, without needing to re-read the full plan. What that requires varies by module, but typically includes: what the module does, what interfaces it depends on and provides, what must be implemented before it, whether it can be worked in parallel, any characterization findings that constrain it, and open questions that need resolution before or during specification.

Each entry must also state explicit **acceptance criteria** for the implementation phase: at minimum, which BDD tests must pass and which interface contract must be satisfied. Add any non-behavioral constraints (performance bounds, error handling mandates, resource limits) that the BDD tests do not cover. Keep this short — if it needs more than a few lines, the module scope is probably too broad.

Err on the side of more context rather than less — a well-specified module entry is the primary handoff artifact of this planning phase.

## Output
Write the migration plan to the artifact path supplied by the orchestrating workflow, typically `<artifact_dir>/plan.md`.

Do **not** write a root-level `plan.md` or a `plan/` directory in the target/output repository unless the human explicitly asks for that location. The discovery workflow keeps planning artifacts with the other discovery artifacts so the workflow can be reconstructed from `artifact_dir`.

If the human explicitly allows Git-provider issues instead of files, write issues only after confirming that choice with the human.