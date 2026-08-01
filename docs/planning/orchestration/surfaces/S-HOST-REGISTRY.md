# Surface S-HOST-REGISTRY — wild: dispatch table

**Status:** FREEZE for WP-4 (implementable)  
**Spike:** SPIKE-RESOLUTIONS S1  
**Homes:** `mycelium-interp` (table) · `mycelium-std-sys-host` (install) · `mycelium-cli` (bind)

## Public contract (v0)

```rust
// mycelium-interp
pub type HostCallRegistry = PrimRegistry; // wild: namespace of PrimRegistry
pub const WILD_PREFIX: &str = "wild:";

impl PrimRegistry {
    /// Register host op as `wild:{name}` (or pass fully-qualified wild: key).
    pub fn register_host(&mut self, name: &str, f: PrimFn);
    pub fn has_host(&self, name: &str) -> bool;
    // existing: register, get, names, with_builtins, empty
}

pub type PrimFn = fn(prim: &str, args: &[&Value]) -> Result<Value, EvalError>;

/// Batch install helper
pub fn install_host_ops(reg: &mut PrimRegistry, ops: &[(&str, PrimFn)]);
```

```rust
// mycelium-std-sys-host (feature = "host-registry")
pub fn install_default_host_ops(reg: &mut PrimRegistry);
// registers at least: time_mono_nanos, time_wall_nanos, rand_fill
// later: fs_*, process_*
```

```rust
// mycelium-cli (myc run path)
// after PrimRegistry::with_builtins():
//   install_default_host_ops(&mut reg);
//   Interpreter::new(reg, swap)
```

## Name catalog (v0 floor — zipper-owned list)

| wild name | Arity / shape | Effects | Lane that implements body |
|-----------|---------------|---------|---------------------------|
| `time_mono_nanos` | `() -> Binary{64}` (or u64 encoding agreed) | none ambient | sys-host |
| `time_wall_nanos` | `() -> Result<Binary{64}, HostErr>` | entropy-ish wall | sys-host |
| `rand_fill` | `(len: Binary) -> Bytes` or fill pattern | entropy | sys-host |
| `fs_read` | `(path: Bytes/Text) -> Bytes` | fs | sys-host (after RealFs) |
| `fs_write` | `(path, bytes) -> ()` | fs | sys-host |
| `process_spawn` | deferred to PKG-WP5 | process | std-sys / host |
| `http_request` | deferred to PKG-WP6 | net | std-net |

**Rule:** new wild names require zipper PR amending this table **before** implementer lanes use them.

## Error contract (never silent)

- Unregistered `wild:x` → existing `EvalError::UnknownPrim` with capability message
- Host OS failure → explicit `EvalError::PrimType` or dedicated `Host` variant (if added, zipper amends)
- No zero-fill entropy, no wrap on clock

## I/O model

**blocking-hypha:** host fns may block the OS thread. No reactor required in v0.

## Value encoding notes (v0 pragmatic)

Until HostCtx lands, prefer:

- Integers: `Binary{N}` existing encodings used by std-sys floor
- Bytes: `Payload` bytes / existing Bytes repr
- Paths: UTF-8 `Bytes` or Text if frontend has it

Document exact width in implementer tests; if encoding changes, zipper bump.

## Success for zipper lane

- [x] register_host API (runtime#11)
- [ ] Name catalog merged (this file)
- [ ] Contract test: empty builtins has_host false; after install_host_ops true
- [ ] No full fs/process/net in zipper PR
