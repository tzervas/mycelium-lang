# S-WILD-DISCLOSURE-DOC

**Owning repo:** `tzervas/mycelium-l1`  
**Package:** `PKG-INTERP-CORRECTNESS` (https://github.com/tzervas/mycelium-lang/issues/45)  
**Status:** proposed — NOT yet frozen

## Proposed signature

```rust
// checkty.rs check_wild (line 6535-6557), doc/error text hardening only — no behavior change:
// today's error text (still correct, keep) says the wild BODY isn't type-checked. ADD an explicit
// sentence that the *declared/ascribed RESULT type itself* is likewise never verified against what
// the host op actually returns at runtime — currently only implied, not stated.
```

## Rationale

checkty.rs:6535-6557 unconditionally does `Ok((want.clone(), Expr::Wild(body.clone())))` once `expected` is `Some(want)` — zero connection to the actual host op. Reproduced live: `fn main() => Unit !{ffi} = (wild { time_mono_nanos() }) : Unit;` checks clean (rc=0) AND runs clean (rc=0), printing a raw `Value { repr: Binary { width: 64 }, ... }` despite declaring `Unit` — a soundness hole that is completely silent today (no warning anywhere).

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
