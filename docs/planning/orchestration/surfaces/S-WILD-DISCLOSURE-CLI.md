# S-WILD-DISCLOSURE-CLI

**Owning repo:** `tzervas/mycelium-cli`  
**Package:** `PKG-INTERP-CORRECTNESS` (https://github.com/tzervas/mycelium-lang/issues/45)  
**Status:** FROZEN (mycelium-lang PR #49, merged 2026-08-04)

## Proposed signature

```rust
// mycelium-cli, new small helper (only depends on mycelium_core::Node, already a transitive dep):
// fn contains_wild(node: &mycelium_core::Node) -> bool {
//     // exhaustive match over Node's CLOSED, small variant set (Const/Var/Let/Op/Swap/Construct/
//     // Match/Lam/App/Fix/FixGroup — mycelium-core/src/node.rs) — Node::Op{prim,..} where
//     // prim.starts_with("wild:") is true (elab_wild emits exactly `format!("wild:{name}")`,
//     // elab.rs:2062); every other variant recurses into its Box<Node>/Vec<Node> children.
// }
// pub fn wild_boundary_banner() -> &'static str { "myc: NOTE — this program invokes `wild` \
//   host operation(s); their declared result type(s) are AUDITED, not statically or dynamically \
//   verified against what the host operation actually returns (ADR-014/VR-5) — a host op returning \
//   a different type than declared will not be caught by `check` or `run`." }
// run_single_nodule/run_multi_nodule, right after elaborate() succeeds and before interp.eval_core():
//   if contains_wild(&node) { eprintln!("{}", wild_boundary_banner()); }
```

## Rationale

Mirrors the codebase's own existing precedent for an unconditional disclosure line: `RunReport.cert_mode_line` / `cert_mode_line_for()` (mycelium-cli/src/lib.rs:240-268) is already 'always-print... unconditionally of whether the phylum checked clean' per design-steer P3-Q3a — this reuses that exact pattern for the wild-boundary trust gap instead of inventing a new mechanism. Walking the ELABORATED Node (not the surface Expr AST) was chosen because Node's variant set is small and closed by design (KC-3 'kernel node budget', mycelium-core/src/node.rs) making an exhaustive, low-risk walk straightforward, and because `Node::Op.prim` is a plain `String` (mycelium-core/src/node.rs:31, `pub type Prim = String`) already prefixed `wild:` at exactly the point elab_wild emits it (elab.rs:2062) — a substring check is sufficient and needs no new IR field.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
