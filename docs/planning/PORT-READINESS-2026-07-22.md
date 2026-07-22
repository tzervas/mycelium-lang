# Mycelium port-readiness & gap-closure plan (2026-07-22)

**Scope:** readiness of the Mycelium language for building real host-effect
applications, driven by the two designated first-port targets —
[`gha-runner-ctl`](https://github.com/tzervas/gha-runner-ctl) and
[`tg-agent-relay`](https://github.com/tzervas/tg-agent-relay) — and the **new phyla**
that must be built to close the gaps. Measured against the Rust train **`v0.464.0`**
(`components.lock`), with the toolchain built from the pinned revs (`myc`,
`mycelium-transpile`).

This is a planning/witness doc in the umbrella. Per-component gap notes live in the
component repos (`mycelium-std-sys`, `mycelium-std-io`, `mycelium-l1`,
`mycelium-transpile`); the port-side staging analyses live in the two target repos
(`docs/PORTING_TO_MYCELIUM.md`).

## Verdict

The toolchain is a genuinely engineered, honest, heavily-tested **research compiler**,
but it is **not yet usable for a host-effect application** (a network service, a
subprocess orchestrator). The frontend is mature (functions, ADTs, generics, traits,
pattern matching, closures, modules, `?`) and the pure-logic fragment runs today — a
native port of `gha-runner-ctl`'s pure core type-checks and runs (see that repo's
`mycelium-port/`). What is missing is the entire host-effect surface **and the seam to
reach it**.

## The linchpin: there is no FFI host (verified first-hand)

The single highest-leverage gap is not "add an HTTP library" — it is the **FFI /
host-effect execution seam**. The designated seam, `wild {}`, type-checks but does not
execute. Reproduced against the built `v0.464.0` `myc`:

```
# wild denied outside a @std-sys nodule:
error[myc-check]: `wild` is denied outside a `@std-sys` nodule … (RFC-0016 §8-Q6, LR-9)

# inside `nodule x @std-sys;` with `!{ffi}` declared, it type-checks clean, but:
$ myc run
error[myc-run-residual]: `hostcall` is outside the evaluation-complete fragment
  (RFC-0007 §4.6): a v0 `wild` block body must be a host-call form `name(args…)` …
```

`wild { name(args) }` lowers to a `Node::Op { prim: "wild:name" }`, but the host-call
registry is **empty by design** (RFC-0028 §4.3) — no `wild:` op is registered in
`mycelium-interp` or `mycelium-std-sys-host`. So **no Rust/native function is callable
from Mycelium today.** Until this lands, "bridge the gaps with Rust" is not mechanically
possible — there is no seam to call through.

## Extraction check: these gaps are genuine, not extraction-lag

The monorepo (`tzervas/mycelium`, HEAD `aad96b7`, v0.463.1) was inspected specifically
to test whether a fuller AOT / FFI / networking implementation exists but was simply
not yet extracted to component repos. **It does not.**

- **AOT / native codegen** is *already fully extracted*: `mycelium-codegen`'s
  `llvm.rs` / `trampoline.rs` / `aot.rs` are **byte-identical** to the monorepo's
  `crates/mycelium-mlir`, and the extracted repo is one minor version **ahead**
  (v0.464 vs v0.463). The native backend is real and further than a numeric-kernel toy
  — it compiles `Construct`/`Match`, closures, and tail/non-tail recursion (heap
  trampoline) to genuine native binaries — **but over a narrow `Binary{8}`/`Ternary`
  scalar ABI only**; it refuses recursive heap data, wide values, strings, general
  datatypes, and quantized Dense/VSA (`AotError::Unsupported*`), is test-only, and is
  **not wired into `myc build`** (which packages a content-addressed spore, not an
  executable). The three-way conformance "AOT" is an env-machine interpreter; native is
  a separate subset-scoped path. Generalizing it to `source.myc → native binary` for
  arbitrary programs is real, unbuilt work (the repo's own DN-15/RFC-0004 increment
  tables and the DN-50 "parsable-vs-runnable" frontier note say so).
- **FFI host** and **networking** do not exist in the monorepo either (zero
  `TcpStream`/`socket`/`std::net`/`tokio` across all crates; the `wild:` registry is
  empty by design). Genuine absence, requiring new design (RFC-0028 host-registry
  population; the not-yet-written "R2 distributed-execution" RFC for network-FFI).

**Conclusion:** none of the three readiness gaps is a fast extract-and-wire job. They
are language/stdlib work.

## Why these two targets are nonetheless well-chosen

Both are **fully synchronous** blocking-loop programs (poll + `sleep` / long-poll), so
Mycelium's missing `async`/reactor is **not** on their critical path. Both have large
**pure-logic cores** (the majority of their LOC) that the current frontend + stdlib can
already express: resource-tier accounting, budget fitting, backoff pacing, allowlist
checks (runner); pagination, dedup, routing, formatting, usage accounting (relay). The
host-effect surface each needs is **narrow and nearly identical**.

## New phyla / capabilities to build (the gap-closure set)

Ranked. Tier-0 gates everything; Tier-1 are the host capabilities both ports need
(each becomes a thin Rust-backed host function *once Tier-0 lands*); Tier-2 is
buildable in pure Mycelium.

| # | New capability / phylum | Home | Tier | Notes |
|---|---|---|---|---|
| 1 | **FFI host-effect execution** — populate the `wild:` host-call registry + an effect/host-fn runtime so `wild { name(args) }` executes | `mycelium-l1` / `mycelium-interp` + `mycelium-std-sys-host` | **0** | The linchpin. RFC-0028 §4.3 registry is empty by design; give it real ops. |
| 2 | **Real-OS stdlib floor (M-541)** — wire `std-sys` `RealFs` + `std-io` socket-backed `Substrate::from_fd`; add process/exec + env-mutation/cwd to the audited `@std-sys` floor | `mycelium-std-sys`, `mycelium-std-sys-host`, `mycelium-std-io` | **0/1** | Today `std-fs`/`std-io` run on in-memory substrates; the OS floor is the `wild` seam's first customer. |
| 3 | **`std-net` phylum** — TCP client, **TLS**, minimal **HTTP/1.1 client**, DNS | new `mycelium-std-net` | **1** | Neither target can talk to GitHub/Telegram without this. Single-host client is enough for v0. |
| 4 | **`std-process` phylum** — spawn/exec, args, wait, exit-status, signals | new `mycelium-std-process` (or a `std-sys` module) | **1** | Runner spawns `podman`/`git`/`gh`; relay spawns adapters/`piper`/`ffmpeg`. |
| 5 | **`std-json` (general codec)** — serialize/deserialize arbitrary user types, not just the internal `Value` | `mycelium-std-io` / new `mycelium-std-json` | **1/2** | Pure computation; buildable natively. Both targets need it. |
| 6 | **`std-toml`** — config parsing | new `mycelium-std-toml` | **2** | Relay's `relay.toml`; pure, native. |
| 7 | **CLI arg parsing** | `mycelium-cli-common` / a `std` module | **2** | Runner's 54-attr surface; pure, native. |
| 8 | **FIFO / named-pipe IPC** | `std-process`/`std-sys` | **1/2** | Relay inbound→agent transport. |
| 9 | *(optional, deploy)* **AOT generalization** — extend native codegen beyond the scalar ABI, or bless interpreter-mode daemons | `mycelium-codegen` / `mycelium-cli` | later | Needed for a shipped binary; the interpreter can run a daemon in the interim. |

## The hypha / hyphae concurrency model — how it helps

Mycelium's structured-concurrency model (RFC-0008 §4.5: `hypha`, `fuse`, `xloc`,
`cyst`, `graft`; RFC-0027 regions/supervision) is a good fit for **both** ports and
sidesteps the missing `async`:

- A **hypha** is a single-threaded structured-concurrency unit; cross-hypha transfer
  rides an **affine channel** protocol, with a work-stealing scheduler and supervision
  (`mycelium-std-runtime`, `mycelium-sched`). This is a poll/step model, not
  async/await — which matches the blocking-loop shape of both targets.
- **Runner:** a supervising hypha runs the listen loop and spawns one worker-hypha per
  container lifecycle; the optional wake-server is its own hypha; cross-hypha via affine
  channels instead of `Arc<Mutex>`.
- **Relay:** a poll-hypha feeds a routing-hypha feeds per-backend sender-hyphae over
  channels — a direct match for the current FIFO fan-out.

**Caveat:** the hypha scheduler is compute-poll with **no I/O reactor**. So hyphae give
the *concurrency structuring* for free, but a hypha that performs blocking host I/O
still needs Tier-0/Tier-1: either a "blocking hypha on its own OS thread" execution
mode or an I/O-readiness integration. Design this alongside #1–#4 so the host-effect
floor and the concurrency model compose.

## Sequencing

1. **Now (unblocked):** grow the native pure-core dogfood ports (runner's
   `mycelium-port/`; a relay formatting/routing phylum) with differential tests vs. the
   originals. Surfaces frontend/stdlib bugs with zero dependence on Tier-0.
2. **Unlock:** land **#1 (FFI host)** + **#2 (real-OS floor)** — the master gate.
3. **Host capabilities:** **#3 `std-net`(+TLS)**, **#4 `std-process`** as Rust-backed
   host functions behind the seam; **#5 JSON**, **#6 TOML**, **#7 CLI** in pure Mycelium.
4. **First full port:** `gha-runner-ctl` (leaner, self-contained), then `tg-agent-relay`.
5. **Deploy:** decide interpreter-daemon vs. **#9** AOT generalization for a shipped binary.

## Artifacts / evidence

- Transpiler `--vet` on `gha-runner-ctl`: **16.7% expressible / 0.0% `checked_fraction`**
  (file-gated), gap categories dominated by method-call syntax, multi-statement/
  unit-returning bodies, imports, and non-unsigned types — recorded in
  `mycelium-transpile/docs/`.
- Working native pure-core port: `gha-runner-ctl/mycelium-port/` (`myc check` clean,
  `myc run` → `Binary{1}` true; differential battery, mutation-verified).
- Port staging analyses: PRs on `gha-runner-ctl` and `tg-agent-relay`.
