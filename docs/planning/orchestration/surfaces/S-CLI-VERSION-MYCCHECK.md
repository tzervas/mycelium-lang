# S-CLI-VERSION-MYCCHECK

**Owning repo:** `tzervas/mycelium-check`  
**Package:** `PKG-INTERP-CORRECTNESS` (https://github.com/tzervas/mycelium-lang/issues/45)  
**Status:** FROZEN (mycelium-lang PR #49, merged 2026-08-04)

## Proposed signature

```rust
// src/bin/myc-check.rs, main(), inside the `while let Some(a) = args.next()` loop, BEFORE the
// `_ if path.is_none() => path = Some(a)` catch-all that currently swallows it as a file path:
// "--version" | "-V" => {
//     println!("{} {}", env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"));
//     return ExitCode::SUCCESS;
// }
```

## Rationale

Reproduced live: `myc-check --version` -> rc=66, `io-error: --version: No such file or directory (os error 2)` — confirmed root cause: myc-check.rs's arg loop (lines 43-66) has no `--version` arm, so `_ if path.is_none() => path = Some(a)` treats the literal string `--version` as the oracle-mode input file path, which then fails `read_source`. Consumer contract measured directly in the local ap-workflows checkout (.github/workflows/reusable-ci-mycelium.yml:134-155): `have="$(myc-check --version 2>/dev/null || true)"` then `case "$have" in *"$WANT"*)` — a plain substring match on STDOUT only (stderr is discarded), exit code of `myc-check --version` itself is not checked (the `|| true` swallows it) but MUST print something so `$have` is non-empty, or the workflow explicitly refuses: 'mycelium-version=... was requested but myc-check does not report a version, so the pin cannot be verified.'

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
