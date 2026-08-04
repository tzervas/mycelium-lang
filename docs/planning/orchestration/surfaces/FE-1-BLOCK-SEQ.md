# FE-1-BLOCK-SEQ

**Owning repo:** `mycelium-l1`  
**Package:** `PKG-FRONTEND-ERGONOMICS` (https://github.com/tzervas/mycelium-lang/issues/46)  
**Status:** FROZEN (mycelium-lang PR #49, merged 2026-08-04)

## Proposed signature

```rust
block_expr ::= '{' expr (';' expr)* '}'   // desugars to nested `let _ = a in let _ = b in c`; `{ e }` == `e`; empty `{}` and a trailing `;` before `}` are explicit parse refusals (each names the unit gap). NO new AST node — parser builds the same `Expr::Let{name:"_",ty:None,..}` spine `let _ = a in b` already builds.
```

## Rationale

ALREADY IMPLEMENTED, tested, and passing on unmerged branch/PR tzervas/mycelium-l1#8 (`feat/block-statement-sequencing`, commit bae8075, 72 LOC in parse.rs + 236-LOC test file + EBNF doc update). Verified independently this session: `cargo test --release --test multi_statement_body` on that branch = 10/10 pass, including the parse-AST-identity goal tests. Freezing this EXACT grammar/desugar (not redesigning it) is correct — low-risk, small, already reviewed-by-tests. Rebase gap from its base commit (08c1d00) to current `dev` tip (5c031df) is 1 commit touching only `.github/workflows/fleet-ci.yml`, `fleet-security.yml`, `docs/FLEET_STANDARDS.md` — zero parse.rs conflict risk, verified by `git diff --stat 08c1d00..origin/dev`.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
