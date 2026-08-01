# Spike resolutions — registry · hypha · TLS (2026-08-01)

**Status:** recommended closed for implementation (evidence-driven).  
**Hub:** train WP-0…WP-4 · decisions package · PORT-READINESS-2026-07-22.

These three items were left *undecided* in the gap Q&A. They are closed here so Tier-0 can implement without inventing architecture mid-PR.

---

## S1 — HostCallRegistry home

### Options considered
| Option | Pros | Cons |
|--------|------|------|
| A. Trait in **interp** + install at **myc CLI** | Execution owns dispatch; CLI owns process-level binding | Install path must stay explicit |
| B. Expand **std-sys-host** only | Already “production host wiring” (RFC-0028 §4.5) | Must not put registry *data structure* only here without runtime knowledge |
| C. New host crate | Clean layering | Premature for train maturity; fan-out cost |

### Evidence
- Registry is **empty by design** (RFC-0028 §4.3); `wild { name(args) }` → `Node::Op { prim: "wild:name" }` then **UnknownPrim** ([mycelium-lang#16](https://github.com/tzervas/mycelium-lang/issues/16)).
- `mycelium-std-sys-host` today is **only** `OsEntropy` + `OsClock` adapters over `std-sys` floor — injectable seams, not a call table.
- `std-sys` floor already has real OS fs/rand/time; host-host is the adapter layer.

### **Decision: hybrid A+B (no new crate)**
1. **`mycelium-interp`** owns `HostCallRegistry` trait + dispatch of `wild:name` (empty default in tests).
2. **`mycelium-std-sys-host`** owns **default host op table** constructors (`install_default_host_ops(reg)`) that register floor-backed ops (`fs_*`, later process/env).
3. **`myc` CLI** (`mycelium-cli` / run path) **installs** the default table before evaluation for `myc run` / `myc check` host-capable modes.
4. Embedders may supply alternate registries (tests, sandboxes).

**Why not C:** phase maturity + multi-repo cost; std-sys-host already named for this role.

**sec inventory:** any host op that escapes sandbox must check myc-sec policy hooks where they exist; v0 ops limited to audited `@std-sys` floor surfaces.

---

## S2 — Hypha + blocking host I/O

### Options considered
| Option | Pros | Cons |
|--------|------|------|
| A. **blocking-hypha** (host I/O blocks OS thread owned by hypha) | Matches both first ports (sync poll+sleep loops); no reactor | Can stall a worker thread |
| B. Full I/O reactor | Ideal long-term | Large design; not needed for runner/relay |
| C. Hybrid | Flexible | Premature complexity |

### Evidence
- PORT-READINESS: both ports are **fully synchronous blocking-loop** programs; missing async is **not** on critical path.
- Hypha scheduler is **compute-poll with no I/O reactor** (RFC-0008 / std-runtime).
- Caveat in plan already names “blocking hypha on its own OS thread” as the composition path.

### **Decision: A for v0 — blocking-hypha**
- Host ops in `wild:` **may block** the calling OS thread.
- Concurrency structure (supervisor/worker hyphae, affine channels) remains for multi-task shape; **do not** pretend non-blocking without a reactor.
- Document: reactor / readiness integration is **post-S1 ports**, not Tier-0.

---

## S3 — TLS / HTTP stack for std-net v0

### Options considered
| Option | Pros | Cons |
|--------|------|------|
| A. **ureq** (+ rustls) | First port **gha-runner-ctl** already uses `ureq` 2.12 blocking+json; tiny surface | Less “framework-y” |
| B. hyper + rustls (+ tokio) | Industry standard | Async — fights S2; heavy for host floor |
| C. reqwest | Convenient | Pulls tokio by default unless blocking feature carefully pinned |

### Evidence
- `gha-runner-ctl` Cargo.toml: `ureq = { version = "2.12", features = ["json"] }`, **forbids unsafe**, deliberately avoids mockito/httpmock/tokio.
- Relay’s Rust workspace is empty (Python core); port will need HTTP client for Telegram/GitHub — same blocking shape.
- S2 chose blocking-hypha → stack must be **blocking**.

### **Decision: A — ureq (blocking) with rustls backend**
- `std-net` wild ops wrap ureq client for HTTP/1.1 + TLS.
- No tokio in the host floor for v0.
- If ureq’s default TLS feature set needs explicit `tls`/rustls, pin in std-sys-host / std-net install crate deps.

---

## Implementation notes (feed WP-4)

```
mycelium-interp:   HostCallRegistry + wild: dispatch
mycelium-std-sys-host: install_default_host_ops + Os* + later process/fs wild bindings
mycelium-cli:      install before run
mycelium-std-sys:  pure floor already mostly present — map to wild names
std-net (later):   ureq-backed wild ops after Tier-0
```

## Traceability
- Decisions Q&A: undecided → **closed by this spike doc**
- Issues: mycelium-lang#16, #17, #18, #19
