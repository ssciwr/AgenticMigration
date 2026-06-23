---
name: bdd-writing-quality
description: >
  Rules and checklists for writing high-quality BDD specifications and converting
  approved BDD specs into executable tests. Covers Gherkin scenario quality,
  scenario coverage requirements, and BDD-to-test traceability.
---

# BDD Writing Quality

## Scope of this skill

This skill applies to **integration and entry-point nodes** (Gherkin feature files) and to the **unit/integration test surface** for all nodes. Leaf nodes produce interface contract specifications, not Gherkin — the relevant quality standard for those is in the bdd-spec-writer agent.

## BDD writing rules

Write behavior, not implementation.

Prefer:

```gherkin
Then the validation error identifies the missing field "dataset_path"
```

Avoid:

```gherkin
Then the ConfigValidator class raises MissingFieldError from line 42
```

Use implementation names only when they are part of the public API or necessary to disambiguate the behavior.

Each scenario should have:

- a specific initial condition,
- one main action,
- observable results,
- enough detail to implement a test,
- no hidden implementation assumptions.

Use concrete examples where possible. Prefer realistic data over placeholders.

Good:

```gherkin
Scenario: Reject a config with an unknown field
  Given a config file containing the unknown top-level field "foo"
  When the config is validated
  Then validation fails
  And the error message includes "foo"
  And no output dataset is created
```

Bad:

```gherkin
Scenario: Config works
  Given a config
  When it runs
  Then it is correct
```

## Scenario coverage checklist

When relevant, cover:

- happy path behavior,
- boundary cases,
- invalid input,
- missing input,
- malformed input,
- empty input,
- duplicate input,
- incompatible state,
- permission or access failure,
- persistence or output side effects,
- idempotency or repeated execution,
- ordering and determinism,
- error messages visible to users,
- compatibility with legacy behavior,
- performance-sensitive behavior if explicitly required,
- security or privacy behavior if relevant,
- dependency interface compliance: protocol conformance, API compatibility, and type or calling-convention constraints imposed by key framework dependencies (e.g. Flux.jl layer protocol, JAX pure-function contract, PyTorch nn.Module interface, Eigen storage-order assumptions),
- framework-specific behavioral contracts that affect correctness or composability (e.g. functional purity required for JAX jit/grad, contraction syntax required by TensorOperations.jl, output shape conventions required by a downstream framework).

Dependency interface scenarios are mandatory when `dependency_interfaces` are listed in the module's plan entry, not optional. They are how the behavioral surface anchors the implementation to its architectural context. Do not add irrelevant scenarios just to be exhaustive — but do not omit dependency interface coverage because it feels technical.

A good dependency interface scenario looks like:

```gherkin
Scenario: Layer conforms to Flux.jl layer protocol
  Given a model layer constructed with the default configuration
  When it is passed to Flux.Chain as a component
  Then it initialises without error
  And a forward pass with a valid input tensor returns an output of the expected shape
```

Not:

```gherkin
Scenario: Layer works with Flux
  Given a layer
  When used with Flux
  Then it works
```

## BDD-to-test mapping

For every implemented scenario, preserve traceability.

Prefer a real BDD/Gherkin runner when the target language has a viable one. The approved `.feature` files should remain the source of truth, and executable tests should be step definitions or runner glue for those features rather than separate broad tests that approximate the scenarios.

Framework guidance:

- Julia: prefer `Behavior.jl` where viable. Add it to the package/test dependencies, run approved `.feature` files from the package test command, and keep step definitions in the configured steps directory.
- Python: prefer `pytest-bdd` or `behave` where viable. Keep feature files and step definitions linked through the selected framework.
- Other languages: select an idiomatic BDD runner if one is available and maintained. Ask the human for clarification if none is available.

Use one or more of these mechanisms depending on the selected framework:

- `.feature` files with scenario names matching the approved spec,
- framework step definitions bound to the feature text,
- BDD runner configuration included in the package test command,
- ordinary tests named after scenario intent only when no viable BDD runner exists,
- comments linking fallback test cases to scenario names,
- test parametrization that preserves example names,
- fixture names that reflect domain vocabulary.

Each test should map back to approved behavior.

## Dual test surface

The created test artifacts differ by node type and are created alongside the respective `.feature` file (inner nodes) or interface contract spec:

**Leaf nodes** (no in-migration children in the plan tree):
- Unit tests in the target language's native test framework (e.g. `@testset` in Julia, `pytest` functions in Python, `#[test]` in Rust). Unit tests cover the module's concrete implementation interface, its dependency interface contracts, and low-level edge cases that are too detailed for Gherkin scenarios.

**Integration nodes** (compose child modules):
- BDD step definitions or runner glue that execute the approved `.feature` file.
- Integration tests that verify child module outputs compose correctly at the boundary defined by the plan. Integration tests use the target language's native test framework or a higher-level runner.

The two surfaces are complementary, not redundant:
- BDD scenarios capture observable behavior at the module boundary — they survive interface refactors and remain readable by non-engineers.
- Unit and integration tests pin the concrete implementation contracts, including dependency interface compliance, and give the worker a fast green/red signal during implementation.

Do not collapse them. Do not rely on BDD scenarios alone to validate interface compatibility, and do not write unit tests that tautologically assert an interface.

## Handling Gherkin specs in test implementation

When implementing Gherkin scenarios:

- preserve feature and scenario names,
- use Background only when shared setup is truly shared,
- keep step definitions reusable but not overly generic,
- avoid regex step definitions so broad that unrelated behavior passes accidentally,
- prefer domain-specific fixtures over incidental implementation setup,
- make assertions on observable outcomes, not internal implementation details,
- include negative assertions when side effects must not occur.

## Handling ordinary tests from BDD specs

If the project does not use a Gherkin runner, implement ordinary tests that still preserve BDD intent.

Example mapping:

```gherkin
Scenario: Reject a config with an unknown field
```

can become:

```python
def test_rejects_config_with_unknown_field(...):
    ...
```

Include comments or docstrings when needed to link the test to the approved scenario.
