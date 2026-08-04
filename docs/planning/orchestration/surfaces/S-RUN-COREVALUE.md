# S-RUN-COREVALUE

**Owning repo:** `tzervas/mycelium-cli`  
**Package:** `PKG-INTERP-CORRECTNESS` (https://github.com/tzervas/mycelium-lang/issues/45)  
**Status:** proposed — NOT yet frozen

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
