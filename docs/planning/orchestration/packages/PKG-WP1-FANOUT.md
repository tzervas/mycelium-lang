# PKG-WP1-FANOUT: Merge docs+CI fan-outs then measured re-pin

**WP:** WP-1/WP-2 · **Priority:** P1 · **Status:** ready  
**Hub:** https://github.com/tzervas/mycelium-lang/issues/30  
**Title prefix:** `train/gap-closure:`

## Goal

Land open docs GAP-STATUS and CI fleet tier-label trains, then run measured full draw-in and update components.lock.

## Non-goals

- Language features
- Host ops

## Surfaces

- `S-ECOSYSTEM-LOCK`

## Lanes

| Lane | Repo | Role | Depends |
|------|------|------|---------|
| L-DOCS | tzervas/mycelium-lang | implementer | — |
| L-CI | multiple mycelium-* | ci | — |
| L-REPIN | tzervas/mycelium-lang | implementer | L-DOCS, L-CI |

## Success criteria (package)

- [ ] Fan-outs merged
- [ ] Measured re-pin commit on umbrella

## Adversarial checklist

- [ ] Do not claim buildable without running draw-in
- [ ] No PIN_LIMIT silent success

## Kickoff prompt (copy to agent)

```
PACKAGE PKG-WP1-FANOUT: merge docs+CI fan-out trains then measured components.lock re-pin.
Hub #30. Decision: merge-then-repin. Do not start language features. Report draw-in JSONL summary on hub.
```

## Blocked by / unblocks

- **Blocked by:** PKG-WP0-LOCK
- **Unblocks:** honest tip for WP-4 repin
