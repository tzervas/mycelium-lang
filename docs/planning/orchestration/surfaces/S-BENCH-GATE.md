# S-BENCH-GATE

**Owning repo:** `tzervas/mycelium-bench`  
**Package:** `PKG-CI-TRUTH` (https://github.com/tzervas/mycelium-lang/issues/48)  
**Status:** FROZEN (mycelium-lang PR #49, merged 2026-08-04)

## Proposed signature

```rust
New CI step layered on top of this repo's S-RUST-CI-CALLER adoption (it is one of the 49 real repos). Added job/step (NOT expressed via reusable-ci-rust's generic `bench: run` input, which runs `cargo bench` against Criterion `[[bench]]` targets — this repo has none; its harness is a `[[bin]] name="bench"`, so the generic input would be vacuously green or a no-op):
  - name: run the real bench harness
    run: cargo run --release --bin bench -- --out reports --stdout
  - name: assert non-trivial report
    run: |
      set -eu
      test -s reports/latest-report.json
      cases=$(python3 -c "import json,sys;print(len(json.load(open('reports/latest-report.json'))['run']['cases']))")
      test "$cases" -gt 0
  - uses: actions/upload-artifact@v7
    with: {name: bench-report-${{ github.run_id }}, path: reports/}
```

## Rationale

`bench.rs` already refuses debug builds and already emits a real deterministic report (measured: backend.rs/corpus.rs/measure.rs/report.rs/verdict.rs exist and are non-trivial) — the gap is that NO CI path invokes it (this repo's current ci.yml only runs `cargo test`) and the generic reusable `bench` input's `cargo bench` semantics do not match this repo's custom-binary harness shape. This closes the gap without inventing new harness code, and gives ZIPPER's 'bench=run must FAIL_ENV without a device' posture something real to eventually gate once/if a GPU-dependent backend exists (none currently does — mlir-dialect gracefully Skips without the LLVM/MLIR toolchain, which is a capability Skip, not a device FAIL_ENV; whether a GPU dimension is needed at all is flagged unknown for human call).

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
