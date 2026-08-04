# S-CLI-TYPED-PRIM-WIRING

**Owning repo:** `mycelium-cli`  
**Package:** `PKG-LINKAGE` (https://github.com/tzervas/mycelium-lang/issues/44)  
**Status:** FROZEN (mycelium-lang PR #49, merged 2026-08-04)

## Proposed signature

```rust
New opt-in features typed-std-io, typed-std-net (mirroring the EXISTING host-registry/net-host feature pattern exactly, verified in mycelium-cli/Cargo.toml); fn install_typed_std(prim_reg:&mut TypedPrimRegistry, prim_env:&mut TypedPrimEnv) called from exactly ONE site before both check and run/build paths; assemble_and_check_phylum changed from check_phylum(&phylum) to check_phylum_with_deps_and_prims(&phylum, &Phyla::default(), &prims)
```

## Rationale

Confirmed gap: mycelium-cli/src/lib.rs's assemble_and_check_phylum calls plain check_phylum today -- zero deps/prims wiring exists in the actual myc binary despite check_phylum_with_deps being library-tested. Populating BOTH TypedPrimEnv (check-time) and TypedPrimRegistry (run-time) from ONE call site directly forecloses a version-skew class of bug analogous in shape to measured defect #3 (check/run divergence on the wild path).

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
