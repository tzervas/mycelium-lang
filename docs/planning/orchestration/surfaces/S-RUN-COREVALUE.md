# S-RUN-COREVALUE

**Owning repo:** `tzervas/mycelium-cli`  
**Package:** `PKG-INTERP-CORRECTNESS` (https://github.com/tzervas/mycelium-lang/issues/45)  
**Status:** CORRECTED 2026-08-04 — the originally proposed path was wrong

## Proposed signature

```rust
// src/lib.rs, run_single_nodule() and run_multi_nodule(), both currently at:
//   let value = interp.eval(&node).map_err(...)?;
//   ... rendered: format!("{value:?}")
// becomes:
//   let value: mycelium_interp::CoreValue = interp.eval_core(&node).map_err(...)?;
//   ... rendered: render_core_value(&value)
//
// new fn (mycelium-cli, not mycelium-interp — CoreValue/Datum expose no Display today):
// fn render_core_value(cv: &mycelium_interp::CoreValue) -> String {
//     match cv {
//         CoreValue::Repr(v) => format!("{v:?}"),  // UNCHANGED from today's Value{...} debug form
//         CoreValue::Data(d) => render_datum(d),    // NEW: recursive, content-addressed, uses
//     }                                             // Datum::ctor()/fields() + CtorRef's own
// }                                                  // Display ("#<hash>#<i>") — never fabricates
//                                                     // a name (ADR-003; see non_goals).
```

## Rationale

eval_core()/CoreValue already exist unchanged in mycelium-runtime (crates/mycelium-interp/src/lib.rs:699-724, confirmed by reading source) — the CLI is the only thing that needs to change. Reproduced live: `fn main() => Unit = Unit;` checks clean (rc=0) then `myc run` fails rc=65 `error[myc-run-eval]: the program evaluated to a data value; use eval_core for the data fragment` (that literal message is EvalError::DataResult's own Display text, lib.rs:359-362). CoreValue::Data wraps a Datum (mycelium-core/src/datum.rs) whose ctor is a content-addressed CtorRef (`#<decl-hash>#<index>`, data.rs:45-73) with NO surface name attached post-build (data.rs:130-136 docstring is explicit about this).

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.

## Correction (2026-08-04)

The originally proposed signature named `mycelium_interp::CoreValue`. **That path does not exist for
a downstream crate and would not compile.** Verified in `mycelium-interp/src/lib.rs`: line 129 is a
plain `use mycelium_core::{Alt, CoreValue, Datum, GuaranteeStrength, Node, Repr, Value, WfError};`,
and the crate's `pub use` lines (132-136) re-export `budget`, `host`, `parallel`, `prims` and
`supervise` — but never `CoreValue` or `Datum`.

The implementing lane flagged this rather than silently working around it, which is the behaviour the
freeze contract is meant to produce. The correct spelling is **`mycelium_core::CoreValue`**, reached
via a direct `mycelium-core` dependency pinned to the same commit `mycelium-interp` and `mycelium-l1`
already resolve internally. Function name, arity, match arms and the byte-identical `Repr` rendering
are unchanged; only the fully-qualified type path differs, which is a necessary consequence of Rust's
re-export rules rather than a design change.

Lesson for future surfaces: a proposed signature that names a type through another crate must be
checked against that crate's `pub use` list, not merely against where the type is used.
