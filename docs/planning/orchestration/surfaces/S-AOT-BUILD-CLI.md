# S-AOT-BUILD-CLI

**Owning repo:** `tzervas/mycelium-cli`  
**Package:** `PKG-WP9-AOT` (https://github.com/tzervas/mycelium-lang/issues/47)  
**Status:** FROZEN (mycelium-lang PR #49, merged 2026-08-04)

## Proposed signature

```rust
myc build --native --out <path>  (both required together in V0; no default output path). Pipeline: reuse mycelium_l1::{parse, check_nodule, elaborate} exactly as run_single_nodule() already does (entry="main") -> mycelium_core::Node -> mycelium_mlir::llvm::compile(&node) -> Ok(artifact) => artifact.persist(out) + spore still built as today, exit 0; Err(AotError::ToolchainMissing) => exit 69 error[myc-build-native-toolchain]; Err(other AotError) => exit 70 error[myc-build-native-unsupported], Report names the refused construct and points at the interpreter as the working fallback.
```

## Rationale

mycelium-cli currently depends on neither mycelium-codegen nor mycelium-core; build() only calls mycelium_spore::build_spore (verified). `--native` today falls through with_run_options()'s `_ => usage()` arm to exit 64 — the measured baseline this surface must flip. mycelium_l1::elaborate returns mycelium_core::Node, the exact type mycelium_mlir::llvm::compile consumes, and as of 2026-08-04 mycelium-l1 and mycelium-codegen pin the IDENTICAL mycelium-core rev (57ef45b453eef1f02bdfb1f0cad1034dabd32b1f) — verified by comparing both Cargo.toml files. This is a strong but UNVERIFIED-BY-BUILD signal (three independently git-dep-pinned repos, lockfiles deliberately untracked) and must be the zipper lane's first spike, not assumed.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
