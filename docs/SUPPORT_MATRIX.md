# Mycelium-lang support matrix (progressive)

This umbrella’s **draw-in** and **release** gates expand OS/arch coverage over time.
**Honesty:** only tiers marked **required** block a release. Everything else is
**experimental** (reported, non-blocking) or **planned** (docs only).

## Ubuntu-first (2026-07-24) — experimental cells are off the PR path

`status=experimental` cells **no longer run on push or pull_request.** They run on
the weekly schedule, or on demand via `workflow_dispatch` with
`full_os_matrix=true`.

Why, measured rather than asserted: every experimental **Linux** cell is
`mode: container`, which spins a *nested* podman/docker inside a fleet runner that
is itself a podman container with no engine. Those 6 cells
(`ubuntu-24.04-x64`, `ubuntu-22.04-x64`, `debian-bookworm-x64`, `rocky-9-x64`,
`fedora-x64`, `linux-arm64-emu`) therefore **cannot pass by construction** — the
identical 6 fail on `main` itself. They were 6 permanently-red checks on every PR,
spending wall-clock and burying real signal.

**Ubuntu is not dropped.** The **required** `linux-x64-host` cell runs *natively*
on the fleet host, which is **Ubuntu 24.04.4 LTS**. That is the Ubuntu gate, and it
is green. The container-mode Ubuntu cells added a second, broken path to the same
distro.

`macos-gh` and `windows-gh` do pass, but are out of scope while the port is landing
on self-hosted Linux. They remain on the schedule and on demand.

**Re-enabling:** promote a cell into `draw-in-required` as `mode: native` once the
fleet registers distro-image runners, so per-distro draw-in runs without nesting.
The periodic full-OS suite is intended to live in **`mycelium-lang-myc`**, keeping
the Rust train’s PR path fast.


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
| **RHEL** 9 | planned | UBI/subscription image when available | Same family as Rocky |
| **Fedora** latest | experimental (container) | `fedora:latest` + rustup | Rolling signal |
| **Ubuntu MATE** / desktop spins | planned | Treat as Ubuntu LTS + desktop packages later | “mate” = desktop flavor, not separate toolchain |
| **FreeBSD** | planned | self-hosted or VM label `freebsd` | Needs fleet image |
| **OpenBSD** | planned | self-hosted/VM | Needs fleet image |
| **macOS** | experimental | `macos-latest` (GitHub-hosted) | Expand to self-hosted Mac later |
| **Windows 10 / 11** | planned → experimental via `windows-latest` | GH-hosted first; self-hosted `windows` later | Direct Win support is a goal |

> ¹ **Temporarily demoted from required.** The Ubuntu/Debian/Rocky cells ran via
> `scripts/draw-in-container.sh`, which starts a **nested** podman/docker container. The fleet
> runners are themselves podman-spawned containers with no in-container engine (by design — the
> fleet manager `tzervas/gha-runner-ctl` spins runners up via podman), so nested draw-in cannot
> run there. They stay non-blocking until the fleet registers **distro-image runners** so
> per-distro draw-in runs **natively** (no nesting); then they return to required as
> `mode: native`. The **Linux host** native cell remains the required Linux gate. See
> `tzervas/gha-runner-ctl#28`.

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
