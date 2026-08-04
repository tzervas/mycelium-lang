# S-AOT-CAPABILITY-CORPUS

**Owning repo:** `tzervas/mycelium-codegen`  
**Package:** `PKG-WP9-AOT` (https://github.com/tzervas/mycelium-lang/issues/47)  
**Status:** proposed — NOT yet frozen

## Proposed signature

```rust
crates/mycelium-mlir/tests/capability_corpus.rs: one #[test] per category — {scalar bit/trit ops, non-recursive Construct/Match, tail-position Fix, heap-trampoline Fix/FixGroup (linear-defunctionalized shape only), unquantized Dense element-wise} vs {refused: general Lam/App closures, refused: wide/heap general ADTs+strings, refused: Vsa/quantized Dense, refused: wild/host-effect calls} — each asserting the literal AotError variant (UnsupportedRepr/UnsupportedPrim/UnsupportedNode/UnsupportedScheme/DepthLimit/Overflow) that compile()/compile_and_run() returns today, plus a generated docs/AOT-CAPABILITY.md summary.
```

## Rationale

The only way to measure 'which constructs lower vs refuse, and at which layer' before myc build --native exists at all, since it runs directly against mycelium-codegen's own public API. Grounded in the AotError enum and the explicit refusal lists documented in llvm.rs's and trampoline.rs's own module docs.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
