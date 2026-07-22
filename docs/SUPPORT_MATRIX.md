# Mycelium-lang support matrix (progressive)

This umbrella’s **draw-in** and **release** gates expand OS/arch coverage over time.
**Honesty:** only tiers marked **required** block a release. Everything else is
**experimental** (reported, non-blocking) or **planned** (docs only).


## Component repos are the unit under test

Every required OS/arch cell runs **draw-in across all `components.lock` pins**.
Each pin is a **separate GitHub component repository** (`tzervas/mycelium-*`),
not a path inside this umbrella. The umbrella only orchestrates:

1. Pin set + revs (`components.lock`)
2. Multi-OS/arch matrix (this doc)
3. Per-component JSONL report (`REPORT_JSONL=…`)
4. Release gate when **all components × required OS cells** are green

See [COMPONENT_READINESS.md](./COMPONENT_READINESS.md) and [SHOWCASES.md](./SHOWCASES.md).

## Principles

1. **Simulate a real install** — clone every `components.lock` pin @ rev and run cargo gates.
2. **Core OS/arch first** — prove the common developer path before long-tail platforms.
3. **Progressive expansion** — turn `planned` → `experimental` → `required` when fleet/images exist.
4. **Emulation is allowed** — arm64 / riscv64 may run under QEMU/`podman --platform` on the x64 fleet.
5. **Windows** is a first-class *goal*; native Win10/11 self-hosted labels land later. Until then, GitHub-hosted `windows-latest` is experimental only.

## Architectures

| Arch id | Status | How |
|---------|--------|-----|
| `x64` / `amd64` | **required** | Native self-hosted Linux fleet |
| `x86` / `i686` | planned | 32-bit Linux container / cross |
| `arm64` / `aarch64` | experimental | `podman --platform linux/arm64` (QEMU) on x64 host |
| `arm` / `armv7` | planned | QEMU platform |
| `riscv64` | experimental | `podman --platform linux/riscv64` when image exists |
| `ppc64le` | planned | later |

## Operating systems / environments

| Target | Status | Runner / image | Notes |
|--------|--------|----------------|-------|
| **Linux host** (fleet Podman) | **required** | `[self-hosted, linux, x64, podman]` | Primary path today |
| **Ubuntu** 22.04 / 24.04 | experimental (container)¹ | `ubuntu:22.04`, `ubuntu:24.04` + rustup | Core Debian-family |
| **Debian** bookworm | experimental (container)¹ | `rust:*-bookworm` or debian+rustup | Core |
| **Rocky Linux** 9 | experimental (container)¹ | `rockylinux:9` + rustup | RHEL-compatible stand-in |

> ¹ **Temporarily demoted from required.** These cells ran via `scripts/draw-in-container.sh`,
> which starts a **nested** podman/docker container. The fleet runners are themselves
> podman-spawned containers with no in-container engine (by design — the fleet manager
> `tzervas/gha-runner-ctl` spins runners up via podman), so nested draw-in cannot run there.
> They stay non-blocking until the fleet registers **distro-image runners** so per-distro
> draw-in runs **natively** (no nesting); then they return to required as `mode: native`.
> The **Linux host** native cell above remains the required Linux gate.
| **RHEL** 9 | planned | UBI/subscription image when available | Same family as Rocky |
| **Fedora** latest | experimental (container) | `fedora:latest` + rustup | Rolling signal |
| **Ubuntu MATE** / desktop spins | planned | Treat as Ubuntu LTS + desktop packages later | “mate” = desktop flavor, not separate toolchain |
| **FreeBSD** | planned | self-hosted or VM label `freebsd` | Needs fleet image |
| **OpenBSD** | planned | self-hosted/VM | Needs fleet image |
| **macOS** | experimental | `macos-latest` (GitHub-hosted) | Expand to self-hosted Mac later |
| **Windows 10 / 11** | planned → experimental via `windows-latest` | GH-hosted first; self-hosted `windows` later | Direct Win support is a goal |

## Languages / trains (later)

| Surface | Status |
|---------|--------|
| Rust train (`mycelium-lang` lock) | **active** draw-in |
| Native `.myc` train (`mycelium-lang-myc`) | planned twin matrix |
| Other language bindings | planned |

## Release rule

A **release** succeeds only if every matrix cell with `required: true` is green for the
exact tag rev. Experimental cells may fail without blocking the cut (logged in the run summary).

## Enabling a new OS/arch

1. Add a row to [`.github/draw-in-matrix.json`](../.github/draw-in-matrix.json) with `status: experimental`.
2. Land fleet image or GH-hosted runner proof.
3. Flip to `required` only after N green release candidates.
4. Update this doc’s tables in the same PR.
