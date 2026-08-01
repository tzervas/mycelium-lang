# PKG-WP5-PROCESS-CODECS: Process in std-sys + codecs in std-io

**WP:** WP-5 · **Priority:** P1 · **Status:** blocked  
**Hub:** https://github.com/tzervas/mycelium-lang/issues/30  
**Title prefix:** `train/gap-closure:`

## Goal

After Tier-0 executes, add process/spawn wait kill in std-sys (wild-backed) and general JSON/TOML codecs in std-io (pure).

## Non-goals

- New std-process pin unless surface bloats
- New std-json pin
- async

## Surfaces

- `S-STD-PROCESS`
- `S-CODECS`
- `S-HOST-REGISTRY`

## Lanes

| Lane | Repo | Role | Depends |
|------|------|------|---------|
| L-ZIP | tzervas/mycelium-lang | zipper | — |
| L-SYS | tzervas/mycelium-std-sys | implementer | L-ZIP |
| L-IO | tzervas/mycelium-std-io | implementer | — |

## Success criteria (package)

- [ ] Codecs usable in pure dogfood
- [ ] process wild ops execute

## Adversarial checklist

- [ ] Codecs remain pure
- [ ] Process errors never silent

## Kickoff prompt (copy to agent)

```
PACKAGE PKG-WP5-PROCESS-CODECS. Blocked until PKG-WP4-TIER0 done.
Surfaces S-STD-PROCESS S-CODECS. L-IO can start early (pure). L-SYS after Tier-0.
Hub #30. train/gap-closure: title prefix.
```

## Blocked by / unblocks

- **Blocked by:** PKG-WP4-TIER0
- **Unblocks:** PKG-WP6-NET, port config parsing
