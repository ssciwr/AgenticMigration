# Issue: File reader

## What this module does

Reads raw dataset files from disk and returns an iterator of parsed records in
the normalized `Record` format defined by the dataset loading pipeline interface.

## Part of

Meta-issue: Dataset loading and preprocessing pipeline (#11)

## Interfaces consumed

None — this is a leaf module with no dependencies on other migration modules.
External dependency: the approved file I/O library specified in requirements
(e.g. HDF5, Parquet, CSV — whichever applies to this project).

## Interface provided

```
read_dataset(path: Path) -> Iterator[Record]
```

`Record` is the shared format defined in meta-issue #11. It must be locked
before implementation begins.

Errors:
- `FileNotFoundError` — raised immediately if the path does not exist
- `CorruptRecordError(record_index, reason)` — raised per malformed record,
  non-fatal; caller decides whether to skip or abort

## Dependencies

None. Can begin as soon as the shared `Record` format is agreed.

## Parallel / sequential

**Independent.** Can be implemented in parallel with the sample validator (#13).

## Relevant characterization findings

- **C004** (observed, medium confidence): legacy implementation silently skips
  malformed records. Resolved at plan review: new implementation raises
  `CorruptRecordError` instead.
- **C009** (observed, high confidence): record order is relied upon downstream.
  Preserve insertion-order guarantee in the new implementation.
- **C011** (inferred, medium confidence): legacy implementation loads the entire
  file into memory before returning. New implementation should use a lazy
  iterator per architectural requirements (clean hot-path).

## Open questions

None — all relevant decisions from the characterization report were resolved
at plan review.

## BDD handoff context

The BDD spec for this module should cover:

- successful load of a valid file returning records in insertion order,
- `FileNotFoundError` on a missing path,
- `CorruptRecordError` raised per malformed record (not silent skip),
- iterator behaviour: records are produced lazily, not all at once.

The `CorruptRecordError` path is the most important to specify carefully — the
legacy system discards these silently, but the new behaviour is intentionally
different. The BDD spec should make the new contract explicit and unambiguous
so the implementation cannot accidentally revert to the legacy behaviour.

The `Record` format definition from meta-issue #11 should be included as context
when writing specs.
