# S-AOT-NATIVE-COMPILE

**Owning repo:** `tzervas/mycelium-codegen`  
**Package:** `PKG-WP9-AOT` (https://github.com/tzervas/mycelium-lang/issues/47)  
**Status:** FROZEN (mycelium-lang PR #49, merged 2026-08-04)

## Proposed signature

```rust
impl CompiledArtifact { pub fn persist(&self, dest: &std::path::Path) -> std::io::Result<std::path::PathBuf>; } // copies self.bin to dest before the TmpDir guard drops it; sets 0o755 on unix; returns dest on success
```

## Rationale

CompiledArtifact.bin (crates/mycelium-mlir/src/llvm.rs) lives inside a private TmpDir whose Drop impl does `remove_dir_all`; only `.run()` (execute-in-place, read one stdout line back, then the artifact drops) is public. Nothing extracts the binary before deletion — this is the literal, verified reason `myc build --native` cannot exist yet even for constructs the backend already compiles.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
