# S-NET-HOST-CHECK

**Owning repo:** `tzervas/mycelium-cli`  
**Package:** `PKG-CI-TRUTH` (https://github.com/tzervas/mycelium-lang/issues/48)  
**Status:** proposed — NOT yet frozen

## Proposed signature

```rust
New doc `docs/NET-HOST-GATE-VERDICT.md` (measurement + explicit human verdict, one of: 'benign: feature unification only, no live wild:http_request registration in a default build' or 'ineffective gate: <mechanism>, network egress reachable from `myc run` with default features') plus, gated on that verdict, a CI assertion step in the migrated S-RUST-CI-CALLER caller:
  - name: net-host default-off assertion
    run: |
      set -eu
      cargo tree -e normal --no-default-features --features host-registry -p mycelium-cli | tee /tmp/tree.txt
      ! grep -q 'mycelium-std-net' /tmp/tree.txt
Measurement commands to run and record verbatim in the doc: `cargo tree -p mycelium-cli` (default features), `cargo build --release` then `strings target/release/myc | grep -c http_request` or equivalent symbol check, and a direct repro attempt (`myc run` on a program with no `@std-sys` wild:http_request call, features default, confirming whether the op is registered in the live PrimRegistry vs merely present in the dependency graph).
```

## Rationale

Gap (10) is stated as MEASURED but the mechanism is not in this package's evidence trail (mycelium-cli's Cargo.toml correctly keeps `net-host` out of `default`, and mycelium-std-sys-host does not depend on mycelium-std-net — so the leak, if real, is not a manifest-level typo and needs an actual repro, not a guess). Per the package brief's own instruction this needs 'a human verdict on whether that is benign feature unification or an ineffective gate' — the lane's job is to make that verdict possible and then enforceable, not to silently pick one.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
