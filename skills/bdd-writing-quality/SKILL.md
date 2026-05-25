---
name: bdd-writing-quality
description: >
  Rules and checklists for writing high-quality BDD specifications and converting
  approved BDD specs into executable tests. Covers Gherkin scenario quality,
  scenario coverage requirements, and BDD-to-test traceability.
---

# BDD Writing Quality

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
- security or privacy behavior if relevant.

Do not add irrelevant scenarios just to be exhaustive. Prefer a small set of high-value scenarios over a large vague set.

## BDD-to-test mapping

For every implemented scenario, preserve traceability.

Prefer a real BDD/Gherkin runner when the target language has a viable one. The approved `.feature` files should remain the source of truth, and executable tests should be step definitions or runner glue for those features rather than separate broad tests that approximate the scenarios.

Framework guidance:

- Julia: prefer `Behavior.jl` where viable. Add it to the package/test dependencies, run approved `.feature` files from the package test command, and keep step definitions in the configured steps directory.
- Python: prefer `pytest-bdd` or `behave` where viable. Keep feature files and step definitions linked through the selected framework.
- Other languages: select an idiomatic BDD runner if one is available and maintained.

Use one or more of these mechanisms depending on the selected framework:

- `.feature` files with scenario names matching the approved spec,
- framework step definitions bound to the feature text,
- BDD runner configuration included in the package test command,
- ordinary tests named after scenario intent only when no viable BDD runner exists,
- comments linking fallback test cases to scenario names,
- test parametrization that preserves example names,
- fixture names that reflect domain vocabulary.

Each test should map back to approved behavior.

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
