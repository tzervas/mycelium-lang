# S-AOT-PROBE-HARNESS

**Owning repo:** `tzervas/mycelium-lang`  
**Package:** `PKG-WP9-AOT` (https://github.com/tzervas/mycelium-lang/issues/47)  
**Status:** proposed — NOT yet frozen

## Proposed signature

```rust
scripts/capability-probe.sh: new optional probe header `// @expect-build: <exit>|skip`, parsed/compared exactly like the existing `@expect-run`; when present, additionally runs `myc build --native --out <tmp-path>` inside the probe's scaffolded project and folds the result into the same as-expected/DRIFT accounting and a new `build` column in docs/CAPABILITY-MATRIX.md / capability-matrix.json.
```

## Rationale

The existing harness (in flight on PR #41 'feat/capability-matrix', open, base main, not yet merged) drives only `myc check`/`myc run`; it has no concept of `myc build` at all. This is the only place gap (7) becomes measured-not-asserted in the same location the project already trusts for capability claims — additive only, does not change any of the 15 existing probes' behavior.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
