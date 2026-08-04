# S-STD-IO-TYPED-PRIMS

**Owning repo:** `mycelium-std-io`  
**Package:** `PKG-LINKAGE` (https://github.com/tzervas/mycelium-lang/issues/44)  
**Status:** FROZEN (mycelium-lang PR #49, merged 2026-08-04)

## Proposed signature

```rust
New typed-prims feature (dep:mycelium-interp, following the EXACT host-registry feature precedent already used by mycelium-std-net/mycelium-std-sys-host's Cargo.toml -- verified); pub fn typed_prim_sigs() -> Vec<(&'static str, PrimSig)>; pub fn install_typed_prims(reg:&mut TypedPrimRegistry) registering to_json/from_json/serialize/deserialize with Mycelium-facing signatures that never name Value or Repr
```

## Rationale

This is the keystone's payload deliverable: un-stubs io.myc's own FLAG-io-2 residual ('Value codec not ported to .myc (M-104/FLAG-io-2)', verified present in the current mycelium-std-io-myc port) by giving those functions a real call path that never requires Value as a .myc-nameable type -- the Rust bridge converts the checked argument's runtime mycelium_core::Value internally, invisibly to the .myc caller.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
