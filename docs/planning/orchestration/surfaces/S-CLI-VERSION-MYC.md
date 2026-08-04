# S-CLI-VERSION-MYC

**Owning repo:** `tzervas/mycelium-cli`  
**Package:** `PKG-INTERP-CORRECTNESS` (https://github.com/tzervas/mycelium-lang/issues/45)  
**Status:** proposed — NOT yet frozen

## Proposed signature

```rust
// src/bin/myc.rs, main(), BEFORE the existing `let Some(cmd) = args.next()` dispatch / usage():
// if cmd == "--version" || cmd == "-V" {
//     println!("{} {}", env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"));
//     return ExitCode::SUCCESS;
// }
```

## Rationale

Reproduced live: `myc --version` -> rc=64, prints the full usage block (matches gap 8's measured claim exactly). `cmd.as_str()` match in myc.rs has no `--version`/`-V` arm, falls through to the default `usage()` case. Must run before any manifest/project-dir resolution so it works from any cwd with no `mycelium-proj.toml` present.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
