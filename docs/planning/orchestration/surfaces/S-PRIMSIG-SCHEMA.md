# S-PRIMSIG-SCHEMA

**Owning repo:** `mycelium-runtime (crate mycelium-interp)`  
**Package:** `PKG-LINKAGE` (https://github.com/tzervas/mycelium-lang/issues/44)  
**Status:** proposed — NOT yet frozen

## Proposed signature

```rust
pub struct PrimSig { pub name: &'static str, pub params: Vec<TySpec>, pub ret: TySpec, pub effects: Vec<String>, pub guarantee: mycelium_core::GuaranteeStrength } ; pub enum TySpec { Binary(WidthSpec), Ternary(WidthSpec), Bytes, Bool, Unit, Float, Seq(Box<TySpec>, u32), Adt(String) } (new module, e.g. src/typed.rs, sibling to host.rs)
```

## Rationale

mycelium-l1 already depends on mycelium-interp directly (Cargo.toml pin, and eval.rs already imports mycelium_interp -- confirmed by reading both crates' source), so interp is a safe, non-circular home for the shared schema l1's checker will consume. TySpec deliberately mirrors mycelium-core::Repr's vocabulary (already the shared runtime type-tag every downstream crate depends on) rather than reusing mycelium-l1::Ty directly, which would force interp to depend on l1 and invert the existing dependency direction.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
