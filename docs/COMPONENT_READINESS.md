# Component-repo readiness (Rust train)

The umbrella does **not** implement the language. **Each pin in
`components.lock` is a first-class GitHub component repo**
(`tzervas/<name>`). Draw-in, multi-OS gates, dual-mode showcases, and
gap-closure all target **those repos**.

| Field | Value |
|-------|--------|
| **Lock** | [`components.lock`](../components.lock) — 45 Rust pins (rev + tree) |
| **Native twin train** | `tzervas/*-myc` under [`mycelium-lang-myc`](https://github.com/tzervas/mycelium-lang-myc) |
| **Monorepo archive / design SoT** | `tzervas/mycelium` |

## What “ready” means (per component)

| Layer | Gate |
|-------|------|
| **A. Standalone build** | At locked rev: `cargo check --workspace --all-targets` green on required OS matrix |
| **B. Standalone test** | `cargo test --workspace` green (release / main draw-in) |
| **C. Fleet CI** | Component repo has self-hosted `fleet-ci` / `fleet-security` + branch badges |
| **D. Spec alignment** | Public surface matches monorepo stdlib/kernel specs where applicable |
| **E. Dual-mode surface** | Where cert applies: honest `fast` vs `certified` paths (ADR-032 / RFC-0034) |
| **F. Native twin** | `*-myc` pin exists; DELIVERY honesty recorded (Declared until validated) |

Umbrella **draw-in** = A+B over **all** lock pins, on each required OS/arch cell.

```bash
# All components (from umbrella)
bash scripts/umbrella-draw-in.sh
REPORT_JSONL=component-report.jsonl MODE=check bash scripts/umbrella-draw-in.sh

# One component
COMPONENT=mycelium-core MODE=check+test bash scripts/component-draw-in.sh

# Subset
ONLY_COMPONENTS=mycelium-core,mycelium-value,mycelium-runtime MODE=check bash scripts/umbrella-draw-in.sh
```

## Inventory (Rust train pins)

Status columns are **coordination state** for the multi-OS draw-in program
(2026-07-22). Re-run draw-in to refresh Empirical build/test cells.

| Component | Role | Draw-in unit | Dual-mode relevance | Native twin |
|-----------|------|--------------|---------------------|-------------|
| mycelium-core | Kernel IR / Value / lattice | yes | cert tags on guarantees | mycelium-core-myc |
| mycelium-value | Value model | yes | cert modes | mycelium-value-myc |
| mycelium-runtime | Runtime | yes | fast vs certified exec | mycelium-runtime-myc |
| mycelium-l1 | L1 frontend | yes | — | mycelium-l1-myc |
| mycelium-codegen | Codegen | yes | — | mycelium-codegen-myc |
| mycelium-std-core | std.core | yes | guarantee matrix | mycelium-std-core-myc |
| mycelium-std-error | Error | yes | never-silent | mycelium-std-error-myc |
| mycelium-std-ternary | Ternary | yes | VSA-adjacent | mycelium-std-ternary-myc |
| mycelium-std-content | Content addressing | yes | provenance | mycelium-std-content-myc |
| mycelium-std-dense | Dense tensors | yes | **ML showcase** | mycelium-std-dense-myc |
| mycelium-std-select | Select | yes | — | mycelium-std-select-myc |
| mycelium-std-vsa | VSA | yes | **ML / memory showcase** | mycelium-std-vsa-myc |
| mycelium-std-swap | Swaps | yes | — | mycelium-std-swap-myc |
| mycelium-std-collections | Collections | yes | — | mycelium-std-collections-myc |
| mycelium-std-cmp | Cmp | yes | — | mycelium-std-cmp-myc |
| mycelium-std-iter | Iter | yes | — | mycelium-std-iter-myc |
| mycelium-std-math | Math | yes | **ML numerics** | mycelium-std-math-myc |
| mycelium-std-numerics | Numerics | yes | **ML numerics** | mycelium-std-numerics-myc |
| mycelium-std-text | Text | yes | — | mycelium-std-text-myc |
| mycelium-std-fmt | Fmt | yes | — | mycelium-std-fmt-myc |
| mycelium-std-diag | Diag | yes | EXPLAIN | mycelium-std-diag-myc |
| mycelium-std-recover | Recover | yes | — | mycelium-std-recover-myc |
| mycelium-std-spore | Spores | yes | supply chain | mycelium-std-spore-myc |
| mycelium-std-runtime | std runtime | yes | hypha/colony | mycelium-std-runtime-myc |
| mycelium-std-testing | Testing | yes | — | mycelium-std-testing-myc |
| mycelium-std-io | IO | yes | host effects | mycelium-std-io-myc |
| mycelium-std-fs | FS | yes | host effects | mycelium-std-fs-myc |
| mycelium-std-time | Time | yes | — | mycelium-std-time-myc |
| mycelium-std-rand | Rand | yes | **ML RNG** | mycelium-std-rand-myc |
| mycelium-std-sys | Sys | yes | — | mycelium-std-sys-myc |
| mycelium-std-sys-host | Sys host | yes | — | mycelium-std-sys-host-myc |
| mycelium-std-conformance | Conformance | yes | — | mycelium-std-conformance-myc |
| mycelium-cli-common | CLI shared | yes | — | mycelium-cli-common-myc |
| mycelium-proj | Project model | yes | — | mycelium-proj-myc |
| mycelium-spore | Spore tooling | yes | provenance | mycelium-spore-myc |
| mycelium-build | Build | yes | — | mycelium-build-myc |
| mycelium-check | Checker | yes | — | mycelium-check-myc |
| mycelium-fmt | Formatter | yes | — | mycelium-fmt-myc |
| mycelium-lint | Lint | yes | — | mycelium-lint-myc |
| mycelium-doc | Docs | yes | — | mycelium-doc-myc |
| mycelium-lsp | LSP | yes | — | mycelium-lsp-myc |
| mycelium-cli | CLI | yes | user UX | mycelium-cli-myc |
| mycelium-sec | Security | yes | cert | mycelium-sec-myc |
| mycelium-transpile | Rust→myc | yes | **gap profiler** (not bulk porter) | mycelium-transpile-myc |
| mycelium-bench | Bench | yes | honesty | mycelium-bench-myc |

## Dual-mode expectation (per applicable component)

Mycelium’s product surface includes **two realistic modes** (not marketing
toggles):

| Mode | Intent | When default |
|------|--------|----------------|
| **`fast`** | Loose, high-throughput, still memory-safe; minimal provenance overhead | Prototyping, training loops, interactive tools |
| **`certified`** | Traceable, auditable, EXPLAIN-heavy, guarantee tags enforced | Deploy, audit, regulated / high-assurance paths |

Components that touch guarantees, VSA, dense ops, runtime, or spores should
document **both** paths in their README when cert is meaningful. Showcase
programs live in monorepo `docs/examples/` / planning showcases (see
[SHOWCASES.md](./SHOWCASES.md)).

## Relation to monorepo epics

Component extract repos are **presentation + pin witnesses**. Design truth,
issue epics, and language-completeness gaps remain in `tzervas/mycelium`
(`docs/planning/language-completeness-gap-inventory.md`, self-hosting ledger,
transpiler vet metrics). Closing a component epic requires monorepo criteria
**and** green draw-in for that pin on the required OS matrix.
