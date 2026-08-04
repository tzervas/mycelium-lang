# FE-2-UNIT-PAREN

**Owning repo:** `mycelium-l1`  
**Package:** `PKG-FRONTEND-ERGONOMICS` (https://github.com/tzervas/mycelium-lang/issues/46)  
**Status:** FROZEN (mycelium-lang PR #49, merged 2026-08-04)

## Proposed signature

```rust
expr position: `()` (LParen immediately followed by RParen inside `parse_primary`'s `Tok::LParen` arm) => sugar, parses to the SAME AST as writing `Unit` by hand: `Expr::Path(Path(vec!["Unit".to_owned()]))`.
type position: `()` (same immediate-RParen lookahead inside `parse_base_type`'s `Tok::LParen` arm) => sugar, parses to the SAME `BaseType` as writing `Unit` by hand: `BaseType::Named("Unit".to_owned(), vec![])`.
```

## Rationale

Verified today: `fn f() => Unit = ();` fails with 'expected an expression, found RParen' (parse_primary's LParen arm falls through to parse_expr on `)`); `fn f() => () = ...;` fails with 'expected a type, found RParen' (parse_base_type's LParen arm). Both sites are exact, single-token-lookahead fixes — zero kernel growth, since the `Unit` prelude type + nullary-ctor value ALREADY fully type-check/elaborate/evaluate (`PRELUDE_UNCONDITIONAL_TYPE_NAMES = ["Bool","Unit"]`, confirmed in checkty.rs). SCOPE NOTE verified this session: mycelium-transpile's Rust->`.myc` emission ALREADY maps Rust `()` to the word `Unit` (`type_map.rs:222-233`, cites DN-137 Alt D/M-1102) and does not need the `()` spelling to unblock its current output — this surface is ergonomics for hand-authored `.myc` and for any IR lowering pass that might naturally emit `()`, not a hard transpile gate. Sequence LAST in the l1 lane; if time-constrained, it can be dropped without blocking FE-1/FE-3.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
