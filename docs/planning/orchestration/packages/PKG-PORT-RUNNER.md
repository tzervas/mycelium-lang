# PKG-PORT-RUNNER: Full port gha-runner-ctl (first canary)

**WP:** WP-7 · **Priority:** P1 · **Status:** blocked  
**Hub:** https://github.com/tzervas/mycelium-lang/issues/30  
**Title prefix:** `train/gap-closure:`

## Goal

Full host-effect port of gha-runner-ctl proving realistic usability (canary before self-host).

## Non-goals

- *-myc self-host
- relay port

## Surfaces

- `S-HOST-REGISTRY`
- `S-STD-NET`
- `S-STD-PROCESS`
- `S-CODECS`

## Lanes

| Lane | Repo | Role | Depends |
|------|------|------|---------|
| L-PORT | tzervas/gha-runner-ctl | implementer | — |

## Success criteria (package)

- [ ] Maintainer canary sign-off on hub

## Adversarial checklist

- [ ] Honesty about remaining gaps
- [ ] No fake green without host ops

## Kickoff prompt (copy to agent)

```
PACKAGE PKG-PORT-RUNNER. First acceptance port canary.
Blocked on WP-5/6. Hub #30 + gha-runner-ctl#27. Freeform: both ports before self-host waves.
```

## Blocked by / unblocks

- **Blocked by:** PKG-WP5-PROCESS-CODECS, PKG-WP6-NET
- **Unblocks:** PKG-PORT-RELAY, self-host unfreeze discussion
