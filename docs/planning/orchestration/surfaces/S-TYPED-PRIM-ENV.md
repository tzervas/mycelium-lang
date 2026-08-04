# S-TYPED-PRIM-ENV

**Owning repo:** `mycelium-l1`  
**Package:** `PKG-LINKAGE` (https://github.com/tzervas/mycelium-lang/issues/44)  
**Status:** proposed — NOT yet frozen

## Proposed signature

```rust
pub struct TypedPrimEnv { modules: BTreeMap<String, BTreeMap<String, mycelium_interp::PrimSig>> } (dep-local-name -> nodule-qualified path -> PrimSig); pub fn check_phylum_with_deps_and_prims(phylum:&Phylum, deps:&Phyla, prims:&TypedPrimEnv) -> Result<PhylumEnv, CheckError> (additive over check_phylum_with_deps; TypedPrimEnv::default() must be byte-identical to today's check_phylum_with_deps)
```

## Rationale

Extends the PROVEN DN-113/M-1060 cross-phylum use dep::a.b.Item resolver (resolve_imports, checkty.rs ~line 2839) with a second resolution target beside Phyla's ResolvedPhylum, so use std_io::serialize.to_json; binds a simple name to a PrimSig instead of requiring a fabricated, body-less ResolvedPhylum. Reuses the EXISTING use syntax (UsePath{phylum:Option<String>, path, glob}), the same never-silent unknown-dependency wording, and the same nodule-qualified-path requirement already tested in tests/cross_phylum.rs, instead of inventing new import syntax -- directly answers 'how a .myc source names an imported symbol' by reuse, not invention.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
