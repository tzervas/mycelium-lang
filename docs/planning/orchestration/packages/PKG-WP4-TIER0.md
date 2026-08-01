# PKG-WP4-TIER0: Tier-0 wild registry + default host install + CLI bind

**WP:** WP-4 · **Priority:** P0 · **Status:** zipping  
**Hub:** https://github.com/tzervas/mycelium-lang/issues/30  
**Title prefix:** `train/gap-closure:`

## Goal

Make wild { name(args) } execute against registered host ops for a minimal floor (time + entropy), with install path from std-sys-host and CLI bind on myc run. Unblocks all host-effect work.

## Non-goals

- std-net / HTTP
- process spawn (PKG-WP5)
- AOT generalization
- *-myc self-host
- I/O reactor (blocking-hypha only)

## Surfaces

- `S-HOST-REGISTRY`

## Lanes

| Lane | Repo | Role | Depends |
|------|------|------|---------|
| L-ZIP | tzervas/mycelium-lang | zipper | — |
| L-RT | tzervas/mycelium-runtime | implementer | L-ZIP |
| L-HOST | tzervas/mycelium-std-sys-host | implementer | L-RT |
| L-CLI | tzervas/mycelium-cli | implementer | L-HOST |
| L-ADV | tzervas/mycelium-lang | reviewer | L-RT, L-HOST, L-CLI |

## Success criteria (package)

- [ ] wild:time_mono_nanos executes via myc run smoke
- [ ] Unregistered wild: still explicit error
- [ ] Three component PRs merged or merge-ready
- [ ] components.lock re-pin scheduled (requires_repin)

## Adversarial checklist

- [ ] No new crate invented
- [ ] PrimFn purity: stateful follow-up documented if needed
- [ ] Effect names match @std-sys floor only
- [ ] CLI does not silently skip install on error
- [ ] Action pins via ap-workflows@v0.1 only

## Kickoff prompt (copy to agent)

```
You are a mycelium train agent under zipper methodology.
PACKAGE: PKG-WP4-TIER0
HUB: https://github.com/tzervas/mycelium-lang/issues/30
SURFACE (READ FULLY): docs/planning/orchestration/surfaces/S-HOST-REGISTRY.md
SPIKES: docs/planning/SPIKE-RESOLUTIONS-2026-08-01.md (S1 registry, S2 blocking-hypha)
DECISIONS: lock materializer adopt-now; no new host crate.
YOUR LANE: <L-RT|L-HOST|L-CLI> — touch ONLY that repo.
PIN: use ecosystem-lock-ref + dep-overrides to co-dev against sibling WIP SHAs.
DO NOT: invent wild names not in S-HOST-REGISTRY catalog; add reactor; touch *-myc.
SUCCESS: lane success_criteria + request adversarial review (L-ADV).
TITLE: train/gap-closure: <summary>
```

## Blocked by / unblocks

- **Blocked by:** PKG-WP0-LOCK
- **Unblocks:** PKG-WP5-PROCESS-CODECS, PKG-WP6-NET, ports
