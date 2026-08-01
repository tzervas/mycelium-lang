# Zipper development methodology (mycelium train)

## One-sentence idea

**Freeze the shared seams first** (interfaces, APIs, names, effects, success
criteria), assign **one lane** to own each seam, then **parallelize all
implementations** against those frozen contracts so component repos never
clobber each other.

```
        ┌─────────────────────────────┐
        │  COMMON SURFACE LANE (ZIP)  │  owns HostCallRegistry, HostSig, wild names
        └──────────────┬──────────────┘
           freeze contracts (PR + tag)
                       │
     ┌─────────────────┼─────────────────┐
     ▼                 ▼                 ▼
  runtime lane    sys-host lane      cli lane
  (dispatch)      (install ops)      (bind on run)
     │                 │                 │
     └──────────── merge only if ────────┘
              contract tests still green
```

## Why component repos enable this

Monorepo PR trains fought for the same tree. Decomposed pins mean:

- One agent **only** touches `mycelium-runtime`
- Another **only** touches `mycelium-std-sys-host`
- Another **only** touches `mycelium-cli`
- The **zipper lane** only lands docs + thin trait stubs / contract tests

No path-overlap → max parallel throughput after the planning tax.

## Lifecycle (per work package)

1. **Plan** — orchestrator writes a *package* (this tree) with surfaces, acceptance, deps
2. **Zip** — common-surface lane freezes APIs (may be stubs + tests only)
3. **Fan-out** — implementation lanes run in parallel against frozen refs
4. **Adversarial review** — review agent stress-tests contracts + diffs (never rubber-stamp)
5. **Synthesize / gate** — package pass/fail; kick back individual lanes
6. **Merge train** — hub issue + title-prefix members; re-pin only after measured draw-in

## What a package must contain

See `schemas/work-package.schema.json` and any file under `packages/`.

Minimum:

- Goal + non-goals
- Frozen **surface IDs** (link `surfaces/*`)
- Repo + branch + train hub
- Dependency order (blocked_by / unblocks)
- Deliverables (files, PRs, tests)
- Success criteria (checkable)
- Runner / GPU / lock materializer inputs
- Adversarial review checklist
- Kickoff prompt for the implementer agent (copy-paste ready)

## Roles

| Role | Who | Does |
|------|-----|------|
| **Orchestrator** | Human + top planner agent | Order WPs, open hubs, freeze packages |
| **Sub-planner** | Workflow / agent per WP | Decompose package → lane packages |
| **Zipper agent** | Common surface lane | APIs, names, contract tests only |
| **Implementer** | Per-repo agent | Code against frozen surfaces |
| **Adversarial reviewer** | Tail agent | Kill weak designs; kick back |
| **Merge gate** | Hub / CI | Train-hub green → merge → re-pin |

## Self-hosted fleet notes

- CI compute: homelab self-hosted (`podman`, rootless, **no extra packages** in base image)
- GPU: WSL GPU runners (`gpu` label); `bench=run` must FAIL_ENV without device
- Apply “rootless / minimal packages” constraints **late** in image build workflows, not as a hard top-level assumption that breaks composition
- All GHA action majors pinned centrally in `ap-workflows` (`pins/actions.yml`) and composed down

## Relation to decisions (2026-08-01)

- Materializer *adopt-now* → every multi-repo lane package declares `ecosystem-lock-ref` + `dep-overrides`
- train-hub tracking → every package lists hub issue + title prefix
- Spikes closed → surfaces below are **implementable**, not open design
