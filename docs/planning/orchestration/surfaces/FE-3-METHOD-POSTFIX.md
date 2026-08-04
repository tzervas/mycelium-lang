# FE-3-METHOD-POSTFIX

**Owning repo:** `mycelium-l1`  
**Package:** `PKG-FRONTEND-ERGONOMICS` (https://github.com/tzervas/mycelium-lang/issues/46)  
**Status:** proposed — NOT yet frozen

## Proposed signature

```rust
New rule inside `parse_path` (used ONLY from `parse_primary`'s `Tok::Ident` arm — the plain `parse_path()` used by `use`/`nodule`/`phylum`/pattern/`swap policy` parsing is UNTOUCHED): the greedy `.Ident` chain STOPS the instant the next `.Ident` is immediately followed by `(` — i.e. `path ::= Ident ('.' Ident)*` but never consumes a segment that is itself the head of a call.
New arm inside `parse_app`'s trailing loop (after the existing `while eat(LParen)` call-chaining arm): on `Tok::Dot` with 2-token lookahead confirming `Ident '('` follows, consume `.name(args)` and rewrite `e = App{ head: Path([name]), args: [e, ...args] }` — i.e. `recv.name(args)` desugars, AT PARSE TIME, to EXACTLY the AST `name(recv, args...)` would produce by hand. NO new AST node.
```

## Rationale

Verified today with the exact roadmap repro: `answer().identity()` fails to parse ('expected `;`... found Dot' at 4:31). Verified the disambiguation with the existing M-662 module-qualified-path production is SAFE, not just distinct: `check_path` in checkty.rs UNCONDITIONALLY refuses every multi-segment `Path` in expression position today ('dotted path `d.g` does not resolve — multi-segment qualified-path syntax is deferred in v0 ... (M-662)', reproduced live with `myc check`). Repurposing any `IDENT.IDENT(...)` sequence for method-call sugar collides with ZERO working semantics — only with syntax that was already a 100%-refused dead end. Traced 5 concrete cases (bare-identifier receiver `n.identity()`, call-result receiver `answer().identity()`, chained `a.b().c()`, non-call dotted chain `a.b` unaffected, mixed `a.b.c(x)` where only the trailing call-segment gets sugar and `a.b` still hits the pre-existing refusal) — all resolve to either the intended method-sugar AST or an honest, unchanged, pre-existing check-time refusal; never silent misinterpretation (G2). Directly targets mycelium-transpile's own documented workaround: `src/emit.rs:1567-1568` and `src/prim_map.rs`'s doc header state the transpiler's ONLY current method-call strategy is rewriting `recv.method()` -> `method(recv)` via a hand-maintained `prim_map` table, gapping (never fabricating) any call without an entry — exactly the 31+ 'method sugar' vet count. Once L1 accepts `recv.method(args)` verbatim, mycelium-transpile's existing `Expr::MethodCall` visitor (already present in `emit.rs`, ~line 153) can emit the dot-syntax directly instead of doing per-callee name resolution.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
