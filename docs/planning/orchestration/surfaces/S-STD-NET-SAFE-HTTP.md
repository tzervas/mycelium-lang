# S-STD-NET-SAFE-HTTP

**Owning repo:** `mycelium-std-net`  
**Package:** `PKG-LINKAGE` (https://github.com/tzervas/mycelium-lang/issues/44)  
**Status:** proposed — NOT yet frozen

## Proposed signature

```rust
New typed-prims feature, SPLIT from the heavy ureq/rustls host-registry feature so typed_prim_sigs() (pure signature data) links with no network stack; registers http_request/http_get with a checked result ADT (replacing today's wild-path opaque Seq<Bytes>{3}, verified in host_registry.rs) and effects:["net"] (not "ffi"); wild:http_request and install_http_host_ops stay byte-for-byte unchanged
```

## Rationale

This IS the task's named 'SAFE HTTP consequence': moving http off wild's ascription-trusted Seq<Bytes>{3} onto a checked, effect-declared surface (!{net}, not the blanket !{ffi}). Splitting signature data from the ureq/rustls implementation matters concretely because static myc-check (fact #9: 3.49MB static binary, ap-workflows PR #30) must be able to load typed_prim_sigs() to check .myc callers without linking a TLS stack.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
