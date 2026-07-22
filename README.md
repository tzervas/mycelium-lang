# mycelium-lang

Self-hosted **presentation / re-export umbrella** for Mycelium **Rust** component repos
(PROGRAM-SELFHOST-DECOMPOSE-2026-07-17 Phase R / dual-umbrella split).

<!-- FLEET-BADGES:BEGIN -->
[![CI](https://github.com/tzervas/mycelium-lang/actions/workflows/fleet-ci.yml/badge.svg?branch=main)](https://github.com/tzervas/mycelium-lang/actions/workflows/fleet-ci.yml?query=branch%3Amain)
[![Security](https://github.com/tzervas/mycelium-lang/actions/workflows/fleet-security.yml/badge.svg?branch=main)](https://github.com/tzervas/mycelium-lang/actions/workflows/fleet-security.yml?query=branch%3Amain)
[![Runner](https://img.shields.io/badge/runs--on-self--hosted%20podman-informational)](https://github.com/tzervas/gha-runner-ctl)
<!-- FLEET-BADGES:END -->

## CI surface (honest)

| Workflow | Role |
|----------|------|
| **`ci.yml`** | **Product gate:** lock format + **multi-OS/arch pin draw-in** (required matrix blocks; experimental is non-blocking) |
| **`fleet-ci.yml`** | Fleet hygiene only (no in-repo stack). Does **not** replace draw-in |
| **`fleet-security.yml`** | gitleaks (+ advisory trivy) |
| **`release.yml`** | **Per-release:** required multi-OS draw-in at exact rev → then tag + GitHub Release |

### Progressive OS / arch matrix

See **[docs/SUPPORT_MATRIX.md](docs/SUPPORT_MATRIX.md)** and machine-readable
[`.github/draw-in-matrix.json`](.github/draw-in-matrix.json).

| Tier | Today (required) | Expanding |
|------|------------------|-----------|
| OS | Linux host + Ubuntu 22.04/24.04 + Debian bookworm + Rocky 9 (containers on fleet) | Fedora, FreeBSD, OpenBSD, Ubuntu MATE, RHEL UBI, macOS self-hosted, Win10/11 self-hosted |
| Arch | **x64** native | **arm64** / **riscv64** via Podman QEMU (experimental); x86 later |
| Windows | experimental via `windows-latest` (smoke pins) | direct Win10/11 fleet labels |

Local / operator:

```bash
# Native host draw-in
bash scripts/umbrella-draw-in.sh
MODE=check+test bash scripts/umbrella-draw-in.sh

# Distro container on fleet host (Podman)
IMAGE=docker.io/library/ubuntu:24.04 MODE=check bash scripts/draw-in-container.sh
IMAGE=docker.io/library/rockylinux:9 MODE=check bash scripts/draw-in-container.sh
# Emulated arm64
PLATFORM=linux/arm64 IMAGE=docker.io/library/rust:1.85-bookworm RUST_PREINSTALLED=1 \
  MODE=check PIN_LIMIT=5 bash scripts/draw-in-container.sh
```



## What this is

A clean entry point that **pins** Rust component SHAs (see [`components.lock`](./components.lock))
and documents how to use the language surface without browsing the historical monorepo.

| Field | Value |
|---|---|
| **Monorepo archive** | `tzervas/mycelium` tag `archive/main-pre-component-transpile-2026-07-17` @ `aad96b7a425710db5e91094d4fc2ca21a129e41a` |
| **Native .myc train umbrella** | [`tzervas/mycelium-lang-myc`](https://github.com/tzervas/mycelium-lang-myc) |
| **Component map** | monorepo `docs/planning/gap-analysis-2026-07-16/COMPONENT-REPO-MAP-DRAFT.md` |
| **Honesty** | Umbrella is operational wiring; not DN-88 production-ready dogfood; not a SemVer 1.0 claim |
| **Train** | **v0.464.0** (course-correction Phase B, 2026-07-18) — all 45 Rust component pins are **verified buildable** (fmt + clippy `-D warnings` + tests green standalone). Pins carry rev **+ content hash** (git tree hash). |

## Component groups (Rust)

- **Kernel:** mycelium-core, mycelium-value, mycelium-runtime, mycelium-l1, mycelium-codegen
- **Std:** mycelium-std-*
- **Tooling:** mycelium-check, mycelium-transpile, mycelium-cli, …

## Pin policy

`components.lock` records each component tip SHA after seed push. Update pins
only via PR here; CI should verify pins resolve (future).

## CI

Workflows run on **self-hosted** runners managed by [`gha-runner-ctl`](https://github.com/tzervas/gha-runner-ctl)
(`runs-on: [self-hosted, linux, x64, podman]`). Badges above report status for **this branch**.

## Relation to monorepo / native train

The monorepo `tzervas/mycelium` remains the **archive + active development** trunk until cutover.
This umbrella does **not** delete monorepo content. Native `.myc` ports are fronted by
`mycelium-lang-myc`; Rust components here remain transitional until native is stable enough to archive.
