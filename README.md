# mycelium-lang

Self-hosted **presentation / re-export umbrella** for Mycelium component repos
(PROGRAM-SELFHOST-DECOMPOSE-2026-07-17 Phase R).

## What this is

A clean entry point that **pins** component and `*-myc` sibling SHAs (see
[`components.lock`](./components.lock)) and documents how to use the language
surface without browsing the historical monorepo.

| Field | Value |
|---|---|
| **Monorepo archive** | `tzervas/mycelium` tag `archive/main-pre-component-transpile-2026-07-17` @ `aad96b7a425710db5e91094d4fc2ca21a129e41a` |
| **Component map** | monorepo `docs/planning/gap-analysis-2026-07-16/COMPONENT-REPO-MAP-DRAFT.md` |
| **Honesty** | Umbrella is operational wiring; not DN-88 production-ready dogfood; not a SemVer 1.0 claim |
| **Train** | **v0.464.0** (course-correction Phase B, 2026-07-18) — all 45 Rust component pins in `components.lock` are **verified buildable** (fmt + clippy `-D warnings` + tests green standalone at the pinned revs; `Empirical`, per-repo CI is the running witness). Pins carry rev **+ content hash** (git tree hash). `*-myc` pins remain `Declared` seed pins until the Phase E/F delivery+validation program |

## Component groups

- **Kernel:** mycelium-core, mycelium-value, mycelium-runtime, mycelium-l1, mycelium-codegen (+ `-myc` twins)
- **Std:** mycelium-std-* (+ `-myc` twins)
- **Tooling:** mycelium-check, mycelium-transpile, mycelium-cli, …
- **Compiler surface:** mycelium-compiler-myc (`lib/compiler`)

## Pin policy

`components.lock` records each component tip SHA after seed push. Update pins
only via PR here; CI should verify pins resolve (future).

## Relation to monorepo

The monorepo `tzervas/mycelium` remains the **archive + active development**
trunk until cutover. This umbrella does **not** delete monorepo content.
