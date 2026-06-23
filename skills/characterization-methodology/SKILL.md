---
name: characterization-methodology
description: >
  Methodology for characterizing existing system behavior before migration or refactor.
  Defines what counts as observable behavior, observation status classifications,
  evidence requirements, and rules for writing characterization tests.
---

# Characterization Methodology

## Philosophy

A characterization test is evidence, not approval.
Current behavior may later be preserved, changed, removed, or rejected as a bug. The goal is to make current behavior visible and testable, not to decide what should happen next.

Keep a strict boundary:

```text
characterization = current observed behavior
BDD specification = desired approved behavior
```

## What counts as current behavior

Focus on externally observable behavior:

- public API inputs and outputs,
- CLI behavior,
- file formats,
- data schemas,
- validation and error messages,
- persistence side effects,
- generated artifacts,
- numerical outputs and tolerances,
- ordering and determinism,
- configuration behavior,
- compatibility behavior,
- documented user workflows,
- existing test expectations.

Avoid treating private implementation structure as behavior unless it is part of the public contract.
Do not change the source project's code that is to be characterized!

## Observation status

Classify each finding only as one of these statuses:

### Observed

Directly demonstrated by existing tests, docs, command output, fixtures, source behavior, or a focused run.

### Inferred

Likely from source reading or partial evidence, but not directly executed or confirmed.

### Unstable

Observed behavior appears non-deterministic, flaky, environment-dependent, timing-dependent, or sensitive to uncontrolled state.

### Broken

The current system fails, crashes, produces invalid output, or cannot complete for the characterized case. Record the failure as current behavior without deciding whether to preserve it.

### Unknown

Evidence is insufficient to characterize the behavior.

## Evidence rules

Every characterization finding must cite evidence, such as:

- source file path,
- existing test path,
- docs path,
- config file,
- command output summary,
- fixture or sample data,
- observed runtime behavior,
- historical output or golden file.

Do not claim behavior without evidence.

If evidence is incomplete, mark the finding as `unknown` or `inferred` with low confidence.

## Environment documentation

Characterization findings may depend on the execution environment. When capturing behavior, document:

- compiler version and flags (for compiled languages),
- runtime version (Python, Julia, etc.),
- operating system and architecture,
- relevant environment variables,
- working directory and relative path assumptions,
- random seeds or sources of non-determinism,
- external data files or fixtures used,
- any hardware dependencies (e.g. GPU, BLAS implementation).

Without this record, a characterization test that passes today may fail or produce different output on another machine or after a toolchain upgrade — not because the behavior changed, but because the environment did.

Store environment snapshots alongside the test artifacts, for example in a `characterization-env.md` or as pytest metadata.

## Capturing behavior: the golden file pattern
Write a set of characterization tests that capture the current behavior of the sources system.
The core pattern for characterization testing is:

1. prepare a controlled, reproducible input,
2. run the legacy system,
3. capture its output,
4. save the output as a reference snapshot (the "golden file"),
5. on subsequent runs, assert the output matches the snapshot.

How you invoke the legacy system depends on the source language:

- **Compiled binary** (e.g., Fortran, C++): run via subprocess, capture stdout, output files, and return code.
- **Callable in-process** (e.g., Python, TensorFlow): call the function directly from the target language via avaialble wrapper libraries, capture return values and side effects, e.g., for Python→Julia migrations, use PyCall to call the Python legacy source directly from Julia so characterization and implementation tests share the same infrastructure. In cases where this is not possible, use the subprocess pattern as in the `compiled binary` case.

The test harness should be written in the **target language**, so the same golden files can be used to verify the new implementation against the old behavior.

See `references/` for small examples of each invocation style.

## Characterization test-writing rules

When writing characterization tests:

- test current behavior exactly as observed,
- name tests clearly, e.g. `test_characterizes_current_<behavior>()`,
- place tests into a known `target_repository` if it is given, otherwise into the current repository's existing test structure but in a separate directory
- avoid broad snapshots unless they are stable and useful,
- prefer small focused fixtures,
- control randomness, time, filesystem, and environment variables,
- document numerical tolerances explicitly,
- avoid external network or services unless already part of existing tests,
- do not weaken existing tests,
- do not modify production code.

If current behavior appears buggy, still characterize it accurately and mark the observation status as `broken`, `unstable`, or `observed` as appropriate. Do not decide whether it should be fixed.

## Report structure

The characterization report (`characterization-report.md`) must contain these sections:

1. **Scope** — what was characterized and why.
2. **Out of scope** — what was explicitly not characterized.
3. **Sources inspected** — relative paths and why each source was relevant.
4. **Current behavior summary** — short factual prose summary of observed behavior.
5. **Behavior inventory** — structured table of individual findings (see below).
6. **Current-behavior examples** — optional Gherkin-like descriptions of current behavior, clearly labeled as observations, not acceptance criteria.
7. **Suggested characterization tests** — proposed tests and which behaviors they would cover.
8. **Tests written** — test files created or changed; if none, write `none — report-only mode`.
9. **Commands run** — each command, its exit code, and a short result summary.
10. **Decision candidates for the human/BDD phase** — questions raised by observed behavior that require a human decision before migration begins.
11. **Risks and limitations** — gaps, fragile assumptions, or limits of the characterization.

### Behavior inventory table

| ID | Observed Behavior | Evidence | Observation Status | Confidence | Notes |
| --- | --- | --- | --- | --- | --- |
| C001 | Describe the current observable behavior precisely. | Cite file path, test, command output, fixture, or golden file. | observed / inferred / unstable / broken / unknown | high / medium / low | Concise notes. |

Every row must have evidence. Rows without evidence must be marked `unknown` with low confidence.


### Version control inclusion
If the characterization tests are written into a known `target_repository`, create a new commit with the characterization artifacts.