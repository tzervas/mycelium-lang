# PKG-WP0-LOCK: Ecosystem lock materializer + package map

**WP:** WP-0 · **Priority:** P0 · **Status:** implementing  
**Hub:** https://github.com/tzervas/mycelium-lang/issues/30  
**Title prefix:** `train/gap-closure:`

## Goal

Land centralized train control: components.lock + PACKAGE_REPO_MAP materialize into Cargo [patch] via ap-workflows inputs ecosystem-lock-ref and dep-overrides.

## Non-goals

- Changing host-effect language semantics
- Re-pinning all 45 components (WP-2)
- AI model CI

## Surfaces

- `S-ECOSYSTEM-LOCK`

## Lanes

| Lane | Repo | Role | Depends |
|------|------|------|---------|
| L-APW | tzervas/ap-workflows | implementer | — |
| L-LANG | tzervas/mycelium-lang | docs | — |
| L-REV | tzervas/mycelium-lang | reviewer | L-APW, L-LANG |

## Success criteria (package)

- [ ] ap-workflows#27 mergeable green
- [ ] mycelium-lang#29 mergeable green
- [ ] Documented caller example with dep-overrides
- [ ] Surface S-ECOSYSTEM-LOCK matches shipped inputs

## Adversarial checklist

- [ ] No eval of PR title/body into dep-overrides
- [ ] Patch tables use full repo URLs matching Cargo.toml git sources
- [ ] Multi-crate package names all rewritten on repo override
- [ ] Rootless runner: materializer uses python3+curl already on image or pure python urllib

## Kickoff prompt (copy to agent)

```
You are an implementer agent on the mycelium train (zipper methodology).
PACKAGE: PKG-WP0-LOCK
HUB: https://github.com/tzervas/mycelium-lang/issues/30
SURFACE: docs/planning/orchestration/surfaces/S-ECOSYSTEM-LOCK.md
YOUR LANE: only the repo assigned in the package lane (do not edit foreign repos).
READ: DECISIONS-2026-08-01, SPIKE-RESOLUTIONS (N/A for this pkg), EXECUTION-PLAN WP-0.
DELIVER: green PR meeting lane success_criteria; link hub with title prefix train/gap-closure:.
CI: self-hosted fleet; do not apt-get; use existing image tools.
DONE when: success_criteria checked and you request adversarial review.
```

## Blocked by / unblocks

- **Blocked by:** —
- **Unblocks:** PKG-WP4-TIER0, PKG-WP1-FANOUT, all multi-repo feat trains
