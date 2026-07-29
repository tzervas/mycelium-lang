# Mycelium expressibility gaps & staged-development roadmap

| Field | Value |
|-------|--------|
| **Date** | 2026-07-29 |
| **Train (Rust umbrella)** | `v0.464.0` (`components.lock`, 45 pins) |
| **Native twin** | [`tzervas/mycelium-lang-myc`](https://github.com/tzervas/mycelium-lang-myc) (46 `*-myc` pins) |
| **Branch** | `docs/expressibility-gap-roadmap-2026-07-29` |
| **Companion plans** | [`docs/planning/PORT-READINESS-2026-07-22.md`](./planning/PORT-READINESS-2026-07-22.md), monorepo `docs/planning/self-hosting-port-ledger.md`, monorepo `docs/planning/road-to-1.0.0-and-mycelium-rewrite.md` |
| **Honesty** | Coordination + measured inventory. Not a SemVer / DN-88 production claim. Prefer **unknown / needs human** over false closure. |

This document is the **umbrella expressibility map**: what the Rust component train can do today, how far the `*-myc` self-hosting seeds have come, where Mycelium sits relative to Python-ecosystem expectations and full-language expressibility, and the prioritized work packages to reach a **fully developed / staged** Mycelium.

Per-component short status files (`GAP-STATUS.md`) on key Rust repos point back here.

---

## 1. Current state: Rust train vs `*-myc` self-hosting

### 1.1 Dual-umbrella architecture

| Umbrella | Role | Lock | Status (measured) |
|----------|------|------|-------------------|
| **`mycelium-lang`** | Front for **Rust** transitional components | 45 pins (rev + tree hash) | Full-scope draw-in: **fmt/clippy/test green standalone** at locked revs (measured 2026-07-23; `mycelium-fmt` re-pinned after monorepo-relative fixture path) |
| **`mycelium-lang-myc`** | Front for **native `.myc`** seeds | 46 pins | Phase E delivery: **Declared** seed pins; per-repo `DELIVERY.md` honesty (≈26 CLEAN / 20 FINDINGS on seed drafts as of Phase E header) |

Design SoT / archive remains monorepo [`tzervas/mycelium`](https://github.com/tzervas/mycelium) (`archive/main-pre-component-transpile-2026-07-17` @ `aad96b7…` as seed baseline). Component extract repos are **presentation + pin witnesses**, not a second design authority.

### 1.2 Rust train — what is real today

**Kernel & value model (Rust-first, heavily tested research compiler):**

| Group | Components | Expressibility note |
|-------|------------|---------------------|
| Kernel IR | `mycelium-core` | `Value<Repr,Meta>`, guarantee lattice, content-addressing (RFC-0001) |
| Value paradigms | `mycelium-value` | dense, numerics, VSA, select |
| Frontend | `mycelium-l1` | Mature pure fragment: functions, ADTs, generics, traits, pattern match, closures, modules, `?` |
| Runtime | `mycelium-runtime` | scheduler, interp, cert, diag, rt-abi |
| Codegen | `mycelium-codegen` | MIR + MLIR/direct-LLVM; **native path real but scalar-ABI subset** |

**Stdlib (Rust extract, 26 `mycelium-std-*`):** collections, text, error, iter, cmp, math, numerics, dense, VSA, swap, ternary, select, fmt, diag, recover, testing, time, rand, content, conformance, **io/fs (in-memory / thin OS)**, **sys (minimal real host)**, runtime (hypha surface), spore.

**Tooling:** `mycelium-cli` (`myc init|build|check|test|run`), check, fmt, lint, lsp, doc, sec, proj, build, spore packager, bench, **transpile** (Rust→`.myc` gap profiler, not bulk porter).

**Honest limits (verified, not extraction-lag):**

1. **`wild {}` type-checks but does not execute** — host-call registry empty by design (RFC-0028 §4.3). No Rust/native function is callable from Mycelium until the FFI seam lands. → [`#16`](https://github.com/tzervas/mycelium-lang/issues/16)
2. **AOT native is a narrow `Binary{8}`/`Ternary` subset** — not wired into `myc build` as a general executable path. → [`mycelium-codegen#5`](https://github.com/tzervas/mycelium-codegen/issues/5)
3. **IO/FS host effects** — richer APIs exist on in-memory substrates; real OS floor incomplete. → [`mycelium-std-sys#6`](https://github.com/tzervas/mycelium-std-sys/issues/6), [`mycelium-std-io#6`](https://github.com/tzervas/mycelium-std-io/issues/6)
4. **No `std-net` / `std-process` / general JSON/TOML** — genuine absence across monorepo + train.

### 1.3 `*-myc` train — self-hosting maturity

| Layer | Typical `DELIVERY.md` state (Phase E, 2026-07-18) | Implication |
|-------|---------------------------------------------------|-------------|
| Kernel twins (`core-myc`, `value-myc`, …) | **No graduated nodules** — seed drafts `FINDINGS` | Not self-hosted |
| Compiler surface (`mycelium-compiler-myc`) | **9 graduated `lib/compiler/*.myc`** — `CLEAN` | Early Empirical compiler fragments exist |
| Selected std (e.g. `std-io-myc`) | Some graduated files (`lib/io.myc`) + seeds | Partial |
| Tooling twins (`cli-myc`, `transpile-myc`, …) | Mostly seed / no graduated rows; some CLEAN empty checks | Not operational replacements |

**Conclusion:** Rust train is the **executable / buildable** language implementation. `*-myc` is a **Declared→Empirical seed track** for ADR-036 comprehensive dogfooding; it is **not** yet a replace-the-Rust-train surface. Phase-D pilot `checked_fraction` ≈ **28.7%** (monorepo course-correction measure); transpiler vet on real Rust (`gha-runner-ctl`) ≈ **16.7% expressible**.

---

## 2. Gaps vs Python ecosystem expectations (stdlib surface)

Python programmers expect a “batteries included” surface. Mapping **expectation → Mycelium train state** (honest, not aspirational):

| Python-ish surface | Expectation | Mycelium today | Gap severity | Tracking |
|--------------------|-------------|----------------|--------------|----------|
| Integers / arithmetic | unlimited ints, ops | Fixed-width `Binary`/`Ternary`; signed/float paths incomplete for full H1 | Medium | monorepo H1 (B/A) |
| Floats | `float` ubiquitous | Scalar float Repr design-gated (H1-A) | High for numeric Python ports | monorepo float ADR |
| Strings / text | `str` ops, encode | `std-text` present; frontend/value fragment still limited for idiomatic ports | Medium | `std-text`, `l1#6` |
| Collections | list/dict/set | `std-collections` value-semantic | Medium (ergonomics) | std-collections |
| Files | open/read/write/path | Thin real fs + in-memory richer API | High | `std-sys#6`, `std-fs` |
| Networking | `socket`, `urllib`, TLS | **Absent** | **Critical** | `#17` |
| Process | `subprocess` | **Absent** (only `exit`) | **Critical** | `#19` |
| JSON / config | `json`, `tomllib` | `Value`↔JSON only; no TOML | High | `#20`, `std-io#6` |
| Async I/O | `asyncio` | No reactor; hypha poll/step only | High for async-shaped apps; **not** on critical path for sync first ports | design (hypha + host I/O) |
| Threads / pools | `threading`, `concurrent` | Hypha / work-stealing scheduler (compute) | Medium | `std-runtime` |
| Random / time | `random`, `time` | Present with injectable host sources | Low–Medium | std-rand, std-time |
| Testing | `unittest`/`pytest` | `std-testing` property/golden/differential | Medium (ecosystem) | std-testing |
| Packaging | `pip`/`venv` | Spore content-addressed packaging (design-forward) | Medium (different model) | spore, std-spore |
| REPL / scripts | `python -c` | `myc run` pure fragment | Medium until host effects | `#16` |
| C FFI | `ctypes`/`cffi` | `wild` audited floor — **not executable yet** | **Critical linchpin** | `#16` |
| ML numerics | numpy-ish | dense / VSA / numerics / math — **different, native-strength** | N/A (super-set on some axes) | std-dense, std-vsa |

**Net:** Mycelium is **ahead** of Python on content-addressing, guarantee lattice, EXPLAIN, certified swaps, and some ML/VSA surfaces; **behind** on ordinary host-effect app surface (net, process, general codecs, executable FFI). First-port targets (`gha-runner-ctl`, `tg-agent-relay`) are deliberately **sync** so missing asyncio is not the blocker — net/process/FFI are.

---

## 3. Gaps for full expressibility

### 3.1 Type system & frontend surface

Surfaced by `mycelium-transpile --vet` on real Rust and by port dogfood:

| Gap | Signal | Why it matters |
|-----|--------|----------------|
| No unit value `()` | 13+ gaps on runner vet | Side-effecting sequences unrepresentable as ordinary fns |
| No method-call sugar `x.m()` | 31+ gaps | Idiomatic OO/method Rust fails to emit |
| Multi-statement bodies | 38+ gaps | Only single-tail / simple `let` bodies emit cleanly |
| Non-unsigned / string / struct types | 14+ gaps | Imperative domain models resist automatic port |
| Imports / module ergonomics | vet residuals | Multi-nodule programs still friction |

Owning epic: [`mycelium-l1#6`](https://github.com/tzervas/mycelium-l1/issues/6). Pure hand-ports of logic cores **already work** (`gha-runner-ctl/mycelium-port/`); automatic expressibility of idiomatic Rust/Python is the gap.

### 3.2 Async / IO / host effects

| Layer | Gap | Owner |
|-------|-----|-------|
| **Tier-0** | Populate `wild:` registry; execute host-call form | `mycelium-lang#16`, l1 elab, interp, `std-sys-host` |
| **Tier-0/1** | Real-OS floor: process, env mut, net sockets, RealFs | `mycelium-std-sys#6` |
| **Tier-1** | Socket `Substrate::from_fd` | `mycelium-std-io#6` |
| **Tier-1** | `std-net` (TCP+TLS+HTTP client) | `mycelium-lang#17` (new phylum) |
| **Tier-1** | `std-process` (+ FIFO) | `mycelium-lang#19` |
| **Composition** | Hypha + blocking host I/O (no reactor today) | design with Tier-0/1 |

Master epic: [`mycelium-lang#18`](https://github.com/tzervas/mycelium-lang/issues/18).

### 3.3 Package / spore / build

| Capability | State | Gap |
|------------|-------|-----|
| `mycelium-proj` manifests / nodule headers | Extracted, usable | Ergonomics / multi-phylum UX |
| Spore packaging (content-addressed) | Present | Publish registry UX, reconstruction dogfood |
| `myc build` | Spore-oriented, not general native binary | Wire `myc build --native` after AOT generalization |
| AOT deploy | Scalar subset only | `codegen#5` |

### 3.4 Tooling & self-hosting expressibility

| Tool | Rust train | `.myc` twin | Gap |
|------|------------|-------------|-----|
| `myc` CLI | Operational | seed | Host-effect UX once seam lands |
| check / fmt / lint / lsp | Operational | seed | Feature parity + project-wide scale |
| transpile | Gap profiler (`--vet`) | seed | Improve emission % as frontend gaps close; never claim bulk port |
| compiler-myc | n/a (Rust l1) | graduated compiler fragments | Expand until differential replace |

Self-hosting remains **ADR-036 beside-the-Rust** until Empirical twins + differentials land; public “rewrite complete” is Phase II, not a precondition for usable host-effect Mycelium.

### 3.5 Python ↔ Rust ↔ `.myc` triangle

```text
Python source ──(no first-class path)──► .myc
Rust source   ──transpile --vet───────► .myc + gap.json   (low % today)
Rust train    ──hand port / dogfood───► .myc pure cores   (works)
.myc seeds    ──DELIVERY honesty──────► Declared/Empirical twins
```

There is **no** Python→Mycelium transpiler. Expressibility for Python libraries is **conceptual** (stdlib coverage + type/IO model), not mechanical. Rust→Mycelium is mechanical-but-lossy; treat transpile as a **profiler** that ranks surface work (`mycelium-l1#6`, value fragment), not as a ship path.

---

## 4. Prioritized work packages → “fully developed / staged” Mycelium

Definition used here:

| Stage | Meaning |
|-------|---------|
| **S0 Research compiler** | Today: pure fragment, honest refusals, dual umbrellas, measured draw-in |
| **S1 Host-effect usable** | FFI seam + real-OS floor + net/process/codecs → first ports run |
| **S2 Deployable** | AOT (or blessed interpreter-daemon) + spore/native ship path |
| **S3 Ordinary-language ergonomics** | unit/method/multi-stmt; broader types; pytest-class DX |
| **S4 Staged self-host** | Empirical `*-myc` replace path for stdlib/toolchain slices |
| **S5 Fully developed** | Public usability DoD + progressive rewrite toward ADR-038 1.0 rewrite terminal |

### WP-0 — Linchpin (blocks S1)

1. **FFI host-effect execution** — register and run `wild:name` ops.  
   - Issues: `#16`  
   - Repos: `mycelium-l1`, `mycelium-runtime`/`interp`, `mycelium-std-sys-host`

### WP-1 — Real-OS floor (S1)

2. **std-sys host registry + process/env/fs/net floor** — `#` `std-sys#6`  
3. **Socket substrate** — `std-io#6` (fd/socket half)

### WP-2 — Port-critical phyla (S1)

4. **`std-net`** (TCP + TLS + HTTP/1.1 client + DNS) — `#17`  
5. **`std-process`** (+ FIFO) — `#19`  
6. **General JSON + TOML** — `#20` / `std-io#6` codec half (pure, can start early)

### WP-3 — Dogfood ports (validates S1)

7. Finish pure-core expansion + full **`gha-runner-ctl`** native port  
8. **`tg-agent-relay`** native port  

### WP-4 — Deploy path (S2)

9. **AOT generalization** beyond scalar ABI + `myc build --native` — `codegen#5`  
10. Host-effect ops codegen-able once WP-0 lands  

### WP-5 — Frontend expressibility (S3; parallelizable)

11. Unit value, method sugar, multi-statement bodies, broader types — `l1#6`  
12. Transpile re-vet after each frontend win; raise expressible % with **measured** reports  

### WP-6 — Self-host staging (S4; parallel but gated on honesty)

13. Graduate `DELIVERY.md` rows for stdlib pure modules first (JSON/TOML native dogfood)  
14. Compiler-myc expansion + differential vs Rust l1 slices  
15. Only then archive Rust pins for replaced components  

### WP-7 — Staging hygiene (continuous)

16. Keep umbrella `components.lock` re-pin after green draw-in (heads are often **ahead** of lock with CI-only commits — do not claim lock == tip without re-pin)  
17. Multi-OS support matrix remains progressive ([`SUPPORT_MATRIX.md`](./SUPPORT_MATRIX.md))  
18. Dual-mode `fast` vs `certified` documentation where guarantees apply ([`SHOWCASES.md`](./SHOWCASES.md))

**Recommended sequence:** WP-0 → WP-1 → WP-2 → WP-3 for usability; WP-5 and WP-6 codec dogfood in parallel; WP-4 after or beside WP-3 for ship binaries.

---

## 5. Open issue inventory (train snapshot 2026-07-29)

Collected via `gh issue list --state open` on primary + key std component repos under the train workspace.

| Repo | # | Title | Labels | URL |
|------|---|-------|--------|-----|
| `mycelium-codegen` | 5 | [Epic] AOT generalization — `source.myc → native binary` beyond the scalar ABI | epic, mycelium-readiness | https://github.com/tzervas/mycelium-codegen/issues/5 |
| `mycelium-codegen` | 8 | classify_arm stray-self scan lacks member-name shadowing guard for FixGroup | bug, codegen | https://github.com/tzervas/mycelium-codegen/issues/8 |
| `mycelium-l1` | 6 | [Epic] Frontend-surface gaps for ordinary programs (unit value, method sugar, …) | epic, mycelium-readiness | https://github.com/tzervas/mycelium-l1/issues/6 |
| `mycelium-lang` | 7 | Train board: Rust components under mycelium-lang | — | https://github.com/tzervas/mycelium-lang/issues/7 |
| `mycelium-lang` | 16 | [Tier-0 linchpin] FFI host-effect execution seam — make `wild {}` execute | — | https://github.com/tzervas/mycelium-lang/issues/16 |
| `mycelium-lang` | 17 | [Tier-1] New phylum: `std-net` — TCP client + TLS + minimal HTTP/1.1 client | — | https://github.com/tzervas/mycelium-lang/issues/17 |
| `mycelium-lang` | 18 | [Epic] Mycelium host-effect & AOT readiness — close all port-blocking gaps | epic, mycelium-readiness | https://github.com/tzervas/mycelium-lang/issues/18 |
| `mycelium-lang` | 19 | [Tier-1] New phylum: `std-process` — spawn/exec, wait, signals, FIFO | epic, mycelium-readiness | https://github.com/tzervas/mycelium-lang/issues/19 |
| `mycelium-lang` | 20 | [Tier-2] Config/data codecs: `std-json` (general) + `std-toml` | epic, mycelium-readiness | https://github.com/tzervas/mycelium-lang/issues/20 |
| `mycelium-lang-myc` | 1 | Train board: native *-myc components under mycelium-lang-myc | — | https://github.com/tzervas/mycelium-lang-myc/issues/1 |
| `mycelium-std-io` | 6 | [Epic] Socket-backed `Substrate::from_fd` + general struct JSON codec | epic, mycelium-readiness | https://github.com/tzervas/mycelium-std-io/issues/6 |
| `mycelium-std-sys` | 6 | [Epic] Real-OS host-effect floor — process/exec, env-mutation, net, + `wild:` registry | epic, mycelium-readiness | https://github.com/tzervas/mycelium-std-sys/issues/6 |

**Count:** 12 open across inventoried repos.  
**Primary repos with zero open issues:** `mycelium-core`, `mycelium-value`, `mycelium-runtime`, `mycelium-cli`, `mycelium-check`, `mycelium-fmt`, `mycelium-lint`, `mycelium-lsp`, `mycelium-transpile`, `mycelium-build`, `mycelium-proj`, `mycelium-spore`, `mycelium-doc`, `mycelium-sec`, `mycelium-bench`, and most other `std-*` (except `std-io`, `std-sys`).

### Issue triage (2026-07-29)

| Action | Result |
|--------|--------|
| Close fixed-on-main | **0** — no open issue had strong evidence of delivery on default branch |
| `codegen#8` | **Still open** — `classify_arm` FixGroup arm still lacks member-name shadowing guard present in `anf_refs_name` (`llvm.rs`; verified on `main`) |
| Epics `#16`–`#20`, `std-sys#6`, `std-io#6`, `l1#6`, `codegen#5` | **Still open** — host-effect / AOT / surface gaps remain genuine |
| Train boards `#7`, `lang-myc#1` | Left open as coordination trackers |

---

## 6. Component readiness cross-links

- Per-pin roles: [`COMPONENT_READINESS.md`](./COMPONENT_READINESS.md)  
- OS/arch gates: [`SUPPORT_MATRIX.md`](./SUPPORT_MATRIX.md)  
- Port plan (2026-07-22): [`planning/PORT-READINESS-2026-07-22.md`](./planning/PORT-READINESS-2026-07-22.md)  
- Component gap notes:  
  - `mycelium-std-sys` → `docs/GAP-host-effects.md`  
  - `mycelium-std-io` → `docs/GAP-socket-substrate-and-json.md`  
  - `mycelium-l1` → `docs/GAP-ffi-host-and-surface.md`  
  - `mycelium-transpile` → `docs/vet-gha-runner-ctl-2026-07-22/`  
- Per-repo pointers (branch `docs/gap-link-2026-07-29`): `GAP-STATUS.md` on core, value, transpile, cli, and key `std-*`

---

## 7. Residual / needs human

1. **Project board linking** — user account cannot always attach issues to Projects v2 programmatically; add epics to the Mycelium board in the UI if desired.  
2. **Lock vs tip drift** — many component `main` tips are **ahead** of `components.lock` (often fleet CI badge/CI-only commits). Re-pin only after measured draw-in.  
3. **Float / signed / H1 monorepo enablers** — tracked primarily in monorepo planning, not yet mirrored as component epics on every repo.  
4. **Python→Myc path** — policy decision (transpiler vs “hand port / rewrite”) not made; do not invent a tool claim.  
5. **I/O reactor vs blocking-hypha** — design choice still open; needs maintainer input when implementing WP-0/1.  
6. **Whether interpreter-daemon is enough for S2** — product call before investing fully in AOT generalization.

---

## 8. Changelog

| Date | Note |
|------|------|
| 2026-07-29 | Initial umbrella expressibility gap roadmap + issue inventory snapshot |
