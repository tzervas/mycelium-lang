# S-PRIMSIG-SCHEMA

**Owning repo:** `mycelium-runtime (crate mycelium-interp)`  
**Package:** `PKG-LINKAGE` (https://github.com/tzervas/mycelium-lang/issues/44)  
**Status:** FROZEN (mycelium-lang PR #49, merged 2026-08-04)

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

## Correction (2026-08-04): WidthSpec was named but never defined

The proposed signature referenced `WidthSpec` as the width argument to `TySpec::Binary`/`Ternary`,
but **never defined it, and no such type exists upstream.** The implementing lane checked
`mycelium-core` at the pinned rev `57ef45b` and found `Repr::Binary{width:u32}` /
`Repr::Ternary{trits:u32}` — bare `u32`, no `WidthSpec` — and found nothing named `WidthSpec`
anywhere in this orchestration tree either.

Resolved as implemented in mycelium-runtime#18:

```rust
pub struct WidthSpec(pub u32);
```

the monomorphic v0 case, which matches this package's own risk note that "TySpec's monomorphic v0
shape ... is proposed but UNPROTOTYPED — the l1 lane must resolve this during Zip". A newtype rather
than a bare `u32` keeps room for a later symbolic/generic width without a breaking signature change.

Lesson: a frozen signature must define every type it names, or point at the exact upstream definition.
Naming a type that exists nowhere forces the implementer to invent shape — precisely what freezing is
supposed to prevent.
