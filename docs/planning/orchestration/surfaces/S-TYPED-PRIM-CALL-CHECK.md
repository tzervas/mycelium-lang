# S-TYPED-PRIM-CALL-CHECK

**Owning repo:** `mycelium-l1`  
**Package:** `PKG-LINKAGE` (https://github.com/tzervas/mycelium-lang/issues/44)  
**Status:** proposed — NOT yet frozen

## Proposed signature

```rust
NoduleImports gains prim_fns: BTreeMap<String, PrimSig>; the App{head:Path([name])} call-check path gains a prim_fns lookup that verifies arity + per-arg Ty (structural match against TySpec, no coercion) before elaborating to Node::Op{prim: format!("prim:{qualified_name}"), args} (new lowering case, parallel to wild's documented Node::Op{prim:"wild:name"} convention in host.rs, but NEVER wrapped in Expr::Wild and NEVER gated by @std-sys); check_body_effect_coverage gains EffectSource::TypedPrim(name) charging PrimSig.effects (default empty)
```

## Rationale

This is the literal acceptance test the task states: 'myc check VERIFIES arguments and results against a registered signature instead of accepting an ascription on faith.' Because it is never routed through Expr::Wild, it never triggers the hardcoded ("ffi", EffectSource::Wild) insertion at checkty.rs ~line 4694 -- delivering 'pure imports should need no !{ffi}' for free, and letting an effectful typed prim (e.g. http) declare its OWN effect name (e.g. !{net}) instead of the blanket ffi tag wild forces on everything regardless of purity.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
