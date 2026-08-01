# PKG-WP6-NET: std-net ureq+rustls wild-backed client

**WP:** WP-6 · **Priority:** P1 · **Status:** blocked  
**Hub:** https://github.com/tzervas/mycelium-lang/issues/30  
**Title prefix:** `train/gap-closure:`

## Goal

Blocking HTTPS client for GitHub/Telegram via wild:http_request using ureq+rustls.

## Non-goals

- Server sockets
- tokio
- HTTP/3

## Surfaces

- `S-STD-NET`
- `S-HOST-REGISTRY`

## Lanes

| Lane | Repo | Role | Depends |
|------|------|------|---------|
| L-ZIP | tzervas/mycelium-lang | zipper | — |
| L-NET | tzervas/mycelium-std-net | implementer | L-ZIP |

## Success criteria (package)

- [ ] HTTPS GET works from myc smoke

## Adversarial checklist

- [ ] No tokio in host floor
- [ ] Matches ureq decision

## Kickoff prompt (copy to agent)

```
PACKAGE PKG-WP6-NET. blocked on Tier-0. Stack: ureq+rustls blocking.
Surface S-STD-NET. Zipper freezes pin home first. Hub #30.
```

## Blocked by / unblocks

- **Blocked by:** PKG-WP4-TIER0
- **Unblocks:** PKG-PORT-RUNNER, PKG-PORT-RELAY
