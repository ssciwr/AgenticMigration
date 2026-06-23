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

### Dependency interface contracts

For each module, enumerate the framework and library dependencies that constrain its implementation. These are not general transitive dependencies — they are the ones that determine correctness, performance, or architectural compatibility of the module itself.

Examples of the kind of dependency interfaces that must be made explicit:
- A neural-network layer module that must conform to `Flux.Layer` or `Lux.AbstractLuxLayer` protocol in Julia.
- A data pipeline that must produce pytrees compatible with JAX's `jit` and `grad` transformations (implying pure functions with no side effects).
- A numerical kernel that depends on Eigen3 storage-order conventions and expression template semantics.
- A training loop that must be compatible with PyTorch's `nn.Module` interface and optimizer step API.
- An array operation module that must conform to `TensorOperations.jl` contraction syntax.
- A GUI framework that must conform to the design elements of QT

For each such dependency, the plan entry must state:
- The dependency name and relevant version constraints if known.
- What the module must expose or conform to: protocol, type signature, calling convention, memory layout, or behavioral contract.
- What the dependency provides that the module relies on (e.g. "JAX provides JIT compilation; the module must be a pure function — no mutable state, no Python-side side effects").
- If the interface is undecided or cannot be inferred from the source, flag it explicitly as a **human gate in planning**. Do not defer dependency interface decisions to the BDD or implementation phase — the spec writer and test writer both depend on this information being resolved before they begin.

Dependency interfaces are first-class plan content. Treat an unresolved dependency interface the same way you treat an unresolved module boundary: flag it, stop, and ask the human before continuing.

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

### Leaf and integration nodes

Every module in the plan tree is one of two types. Mark this explicitly in each module entry.

- **Leaf node** — has no in-migration child modules. The implementation is self-contained against its interface contract. The BDD review loop will produce an interface contract specification and unit tests for this module.
- **Integration node** — composes one or more child modules. The implementation wires together already-implemented children. The BDD review loop will produce a BDD feature file and integration tests for this module.

The leaf/integration distinction drives the test strategy in both the BDD phase and the implementation phase. A module that is a leaf today but expected to grow children in a later migration wave should be marked leaf for this migration scope.

### Key algorithmic properties

For each module, identify source-observable algorithmic properties that affect behavior and must be preserved or explicitly changed. These are not arbitrary implementation details; they are behavioral algorithms visible through outputs, extension points, state mutation, ordering, errors, performance, or downstream composition.

Extract these properties from the characterization report and source repository where possible. If a key algorithmic property cannot be inferred, flag it as a planning question for the human supervisor.

For each relevant module, state:

- **collection and aggregation semantics**: what is accumulated, over what scope, and when aggregation happens.
  - Example: an import job collects row-level validation errors and emits one summary at the end rather than failing on the first row.
  - Example: a reporting module groups transactions by account and month before applying totals.

  - **data-flow semantics**: how data is represented, transformed, staged, and handed off between processing steps. Record whether the source uses a pipeline, DAG, event stream, queue, transaction
 boundary, shared mutable object, persisted intermediate files, lazy iterator, batch, or request/response flow. Specify where transformations occur, whether intermediate results are materialized or lazy, and what ordering or dependency constraints exist between steps.
     - Example: a build system represents work as a directed acyclic graph where nodes produce artifacts
 consumed by dependent nodes.
     - Example: an image-processing workflow is a pipeline where each stage transforms an image, writes
 an intermediate file, and the next stage reads that file.
     - Example: a streaming importer validates records one at a time but commits accepted records in
 batches at transaction boundaries.

- **callback / plugin semantics**: when user-provided functions are called, with what arguments, and whether their return values are transformed.
  - Example: file parsers are selected from a registry by declared format and receive the raw stream plus parse options.
  - Example: lifecycle hooks run before persistence and may veto the write by returning a specific result.

- **ordering and determinism**: whether ordering, stable keys, iteration order, run naming, sorting, tie-breaking, or seeded randomness affects observable behavior.

- **state mutation semantics**: which inputs or objects are mutated, when, and what state is preserved across calls.
  - Example: a retry controller updates attempt counters and last-error state after each failed call.
  - Example: a configuration expander either mutates the input object in place or returns independent copied configurations.

- **dispatch / selection logic**: how branches are chosen, such as active handlers, strategy selection, parser fallback order, sample-count precedence, cache lookup order, or backend selection.

- **error and short-circuit behavior**: what fails early, what continues, and what error message or error category must identify the problem.

- **extension boundaries**: where behavior is intentionally delegated to user-supplied or framework-supplied functions instead of being hardcoded in the migrated implementation.

Do not merely state that a schema, output column, or interface exists. If behavior depends on how values are produced, the plan must record that production rule.

Each module entry with nontrivial behavior should include a `key_algorithmic_properties` field. If none apply, state `none`.

### Handling ambiguity and risk

Flag rather than decide when:

- the characterization report contains `unknown` or `inferred` findings that affect a module boundary,
- requirements are ambiguous about a module's scope or interface,
- a decision candidate from the characterization report is unresolved and relevant to the plan,
- a dependency interface cannot be inferred from the source and the human has not yet decided it.

Record each flag as an open question in the affected module entry. Do not invent requirements to fill gaps.

### Module entry contents

Each module entry must give the BDD-review-loop enough context to write specifications for that module independently, without needing to re-read the full plan. What that requires varies by module, but typically includes: what the module does, what interfaces it depends on and provides, what must be implemented before it, whether it can be worked in parallel, any characterization findings that constrain it, and open questions that need resolution before or during specification.

Each entry must also state:

- **node_type**: `leaf` or `integration` (see "Leaf and integration nodes" above).
- **dependency_interfaces**: for each framework or library dependency that constrains this module's implementation, the specific interface contract that must be satisfied (see "Dependency interface contracts" above). If there are none, state `none` explicitly — do not omit the field.
- **key_algorithmic_properties**: source-observable algorithms, callback timing, aggregation rules, state mutation, ordering, dispatch logic, and extension semantics that the BDD specs/tests must preserve. If none apply, state `none`.
- **acceptance criteria**: at minimum, which BDD tests must pass, which unit tests must pass (leaf nodes) or which integration tests must pass (integration nodes), and which interface contracts — including dependency interfaces and key algorithmic properties — must be satisfied. Add any non-behavioral constraints (performance bounds, error handling mandates, numerical tolerances, resource limits) that the BDD tests do not cover.

Keep the acceptance criteria short — if it needs more than a few lines, the module scope is probably too broad.

Err on the side of more context rather than less — a well-specified module entry is the primary handoff artifact of this planning phase.

## Remote version control issue writing
If the target repository is under version control and has a remote like github or gitlab, ask the human if you should transfer all the migration plan into issues on the remote platform, using tools you have available. Use the tree structure of the migration plan to create issues and link them in other issues as sub-issues for instance.

## Output
Write the migration plan to the artifact path supplied by the orchestrating workflow, typically `<artifact_dir>/plan.md`.

Do **not** write a root-level `plan.md` or a `plan/` directory in the target/output repository unless the human explicitly asks for that location. The discovery workflow keeps planning artifacts with the other discovery artifacts so the workflow can be reconstructed from `artifact_dir`.

If the human explicitly allows Git-provider issues instead of files, write issues only after confirming that choice with the human.