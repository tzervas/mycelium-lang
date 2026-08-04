# S-TYPED-PRIM-REGISTRY

**Owning repo:** `mycelium-runtime (crate mycelium-interp)`  
**Package:** `PKG-LINKAGE` (https://github.com/tzervas/mycelium-lang/issues/44)  
**Status:** FROZEN (mycelium-lang PR #49, merged 2026-08-04)

## Proposed signature

```rust
pub struct TypedPrimRegistry { .. } with register_typed(name:&str, sig: PrimSig, f: PrimFn), get_typed(name:&str) -> Option<(&PrimSig, PrimFn)>, has_typed(name:&str) -> bool, sigs(&self) -> impl Iterator<Item=&PrimSig>, install_typed_prims(reg:&mut TypedPrimRegistry, ops:&[(&str, PrimSig, PrimFn)]). Dispatch key prefix 'prim:' (PrimRegistry-family, parallel to WILD_PREFIX='wild:').
```

## Rationale

Exact structural mirror of the ALREADY-SHIPPED, spike-resolved HostCallRegistry/install_host_ops/wild: pattern in host.rs (verified: register_host, install_host_ops, empty-by-default, UnknownPrim on miss). Reusing a proven, tested design rather than inventing a new one; 'distinct from the opaque wild: table' per the task framing is satisfied by the separate prim: namespace and separate struct, not by a second parallel PrimRegistry-cloning effort.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
