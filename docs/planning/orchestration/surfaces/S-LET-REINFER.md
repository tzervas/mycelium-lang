# S-LET-REINFER

**Owning repo:** `tzervas/mycelium-l1`  
**Package:** `PKG-INTERP-CORRECTNESS` (https://github.com/tzervas/mycelium-lang/issues/45)  
**Status:** FROZEN (mycelium-lang PR #49, merged 2026-08-04)

## Proposed signature

```rust
// checkty.rs, next to the existing infer_type (pub(crate) fn infer_type, ~line 10387):
// pub(crate) fn infer_type_against(
//     env: &Env, scope: &mut Vec<(String, Ty)>, e: &Expr, expected: &Ty
// ) -> Result<Ty, CheckError> {
//     // identical Cx construction to infer_type (same std_sys:true / ambient_policy:None /
//     // affine:Tracker::inert() / strictness:Strict fields — copy verbatim, do not drift)
//     cx.check(scope, e, Some(expected)).map(|(ty, _)| ty)   // note: .check not .infer
// }
//
// elab.rs, Expr::Let arm (currently line ~1799-1825), currently:
//   Expr::Let { name, ty: _, bound, body } => {
//     let bty = infer_type(self.env, &mut Self::ty_scope(scope), bound)...  // ty discarded!
// becomes:
//   Expr::Let { name, ty, bound, body } => {
//     let bty = match ty {
//       Some(t) => { let (want,_) = resolve_ty(site, &self.env.types, &[], t)?;
//                     infer_type_against(self.env, &mut Self::ty_scope(scope), bound, &want)? }
//       None => infer_type(self.env, &mut Self::ty_scope(scope), bound)?,  // unchanged fallback
//     };
```

## Rationale

Root cause located and reproduced exactly. elab.rs:1799-1825's `Expr::Let` arm destructures `ty: _` — the surface let annotation is thrown away — then calls `infer_type` (checkty.rs Cx::infer, line 5708-5710: `self.check(scope, e, None)`, i.e. forced SYNTHESIS mode). checkty.rs's `check_wild` (line 6535-6557) explicitly refuses in synthesis mode: 'a `wild` block has no synthesizable type ... Ascribe the `wild` block's result type'. Reproduced live: `let discard: Binary{64} = wild { time_mono_nanos() } in discard` inside a `!{ffi}`-effect main checks clean (myc check rc=0) then `myc run` fails rc=70 `error[myc-run-residual]: ... could not re-infer \`let discard\`'s type: check error in \`<elaborate>\`: a \`wild\` block has no synthesizable type ...`. Confirmed the documented workaround (ascribe the block itself, `(wild {...}) : T`) DOES run successfully (rc=0) — traced to check_ascribe (checkty.rs:6891-6898) which independently re-derives `expected = Some(want)` from the Ascribe node's OWN TypeRef regardless of the outer synthesis-mode call, which Expr::Let's discarded `ty` field never gets to do.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
