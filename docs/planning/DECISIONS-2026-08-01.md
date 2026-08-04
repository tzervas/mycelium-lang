# Mycelium Rust train — recorded decisions (2026-08-01)

**Source:** Gap & interface interactive report Q&A  
**Package schema:** `mycelium-gap-report-answers/v1`  
**Exported at:** `2026-08-01T15:33:01.292Z`  
**Progress:** 17 / 17 answered  

This document is the umbrella planning record for decisions that unblock (or constrain) closing host-effect and expressibility gaps on the **Rust baseline** (`mycelium-*`). Native `*-myc` twins remain out of scope until unfreeze.

## Executive constraints

| ID | Decision | Choice |
|----|----------|--------|
| q-lock-materializer | Train control | **Adopt now** — block Tier-0 PRs on lock materializer path |
| q-workflow-lock | ap-workflows inputs | **Accept** ecosystem_lock_ref + dep_overrides + package map as proposed |
| q-inflight-tracking | Multi-repo WIP | **Train-hub** (hub issue/PR + title-prefix members) |
| q-docs-ci-fanout | Open fan-outs | **Merge both** (docs + CI) then **measured draw-in re-pin** |
| q-s2-deploy | Deployable definition | **General AOT / `myc build --native` required** for S2 |
| q-myc-defer | Self-host twins | **Hard freeze** all `*-myc` until explicit unfreeze |
| q-port-order | Acceptance ports | **gha-runner-ctl → tg-agent-relay** |
| q-gpu-vsa | GPU CI | **Require GPU label** for `bench=run` (fail if missing) |
| q-process-home | std-process | **Start in std-sys**, split later if needed |
| q-codec-home | Codecs | **Extend mycelium-std-io** (no new std-json/toml repos for v0) |
| q-frontend-priority | S3 order | **unit → method → multi-stmt → types** |
| q-readme-refresh | Honesty | **Batch README refresh now** |
| q-registry-home | HostCallRegistry home | **Undecided** — spike strata + sec inventory |
| q-blocking-hypha | Hypha + host I/O | **Undecided** — need analysis |
| q-tls-stack | TLS/HTTP v0 | **Undecided** — recommend after spike |

## Freeform (maintainer)

> All self hosting of mycelium lang in mycelium will follow the full porting of the two first port target projects as they prove out if the lang is truly realistically usable and gives canaries for issues to patch out of the lang before the full port waves of the entire lang into itself.

**Interpretation:** Hard freeze on `*-myc` **and** unfreeze is not sufficient alone — both first-port targets must be fully ported and used as canaries before self-host port waves.

## Still open (blockers for some designs)

1. **Registry placement** (interp+CLI install vs expand `std-sys-host` vs new host crate) — spike required.  
2. **Hypha + blocking I/O** (blocking-hypha vs reactor vs hybrid) — analysis required before std-net/process shape locks.  
3. **TLS/HTTP stack** (rustls+hyper / reqwest / minimal) — short spike after FFI seam path is clear.

## Execution order (implied)

1. Land **lock materializer + package→repo map** in `ap-workflows` / umbrella (adopt-now).  
2. **Merge** docs GAP-STATUS + CI fleet tier-label fan-outs → **measured draw-in re-pin**.  
3. **Batch README** honesty refresh (drop path-dep FLAG lag).  
4. Close **spikes**: registry home · hypha I/O · TLS stack.  
5. **Tier-0** multi-repo feat train: wild registry + std-sys floor ops (process in-sys).  
6. Codecs in **std-io**; **std-net**; process; **runner full port** then **relay**.  
7. **S2 AOT** generalization + `myc build --native` (not daemon-only).  
8. **S3** frontend: unit → method → multi-stmt → types.  
9. Keep `*-myc` **hard frozen** until explicit unfreeze **after** both first ports prove realism.

## Publish surfaces

- Issue comments on epics (`mycelium-lang` #7, #16–20, #27; component epics; ports).  
- Project board: attach this decision set / umbrella epic (manual if Projects v2 API unavailable).  
- This file under `docs/planning/` on the umbrella.

## Raw answer package

See companion JSON export at `docs/planning/gap-report-answers-2026-08-01.json` (schema `mycelium-gap-report-answers/v1`).
