# Meta-issue: Dataset loading and preprocessing pipeline

## Overview

Implements the full path from raw input files on disk to validated, preprocessed
samples ready for the training loop. Composed of three sub-modules connected by
two interface boundaries.

## Sub-issues

| # | Module | Type | Status |
|---|--------|------|--------|
| 12 | File reader | leaf, independent | ready to start |
| 13 | Sample validator | leaf, independent | ready to start |
| 14 | Preprocessing pipeline | integration, sequential | blocked on #12 and #13 |

## Interfaces

### Record format (shared by all three sub-modules)

The record format is the critical shared contract. Lock it down before any
sub-issue begins — a change to it during implementation affects all three.

```
Record:
  id:      str          — unique sample identifier
  data:    array[float] — raw feature values, shape (n_features,)
  label:   float        — target value
  source:  Path         — originating file path
```

### FileReader → PreprocessingPipeline

- Output: `Iterator[Record]`
- Errors: `FileNotFoundError` (fatal), `CorruptRecordError` (per-record, non-fatal)
- Ordering: records returned in file insertion order, no deduplication

### SampleValidator → PreprocessingPipeline

- Input: single `Record`
- Output: `ValidationResult(valid: bool, errors: list[str])`
- The preprocessing pipeline calls the validator per record before applying transforms

## Implementation sequence

1. Lock the `Record` format (before either leaf module begins)
2. Implement file reader (#12) and sample validator (#13) in parallel
3. Implement preprocessing pipeline (#14) once #12 and #13 are complete and tested

## Characterization findings

- **C004** (observed, medium confidence): current file reader silently skips
  malformed records without logging. **Decision at plan review**: surface as
  `CorruptRecordError` rather than silent skip, per requirements.
- **C007** (observed, high confidence): preprocessing applies a hardcoded
  normalization constant. **Decision**: must be parameterized in the new
  implementation per architectural requirements (separation of parameterization
  and code).
- **C009** (observed, high confidence): record order is load-order dependent
  downstream. Preserve insertion-order guarantee.

## Open questions

- Should validation errors be collected and reported in batch, or cause immediate
  per-record rejection? Affects the validator interface and the preprocessing
  pipeline's error handling strategy.
- What is the expected behavior when the entire dataset fails validation?

## Risks

The shared `Record` format is the highest-risk interface in this module — it is
consumed by all three sub-issues. Any change to it after implementation begins
will require coordinated updates across all three. Treat it as frozen once the
first sub-issue starts.
