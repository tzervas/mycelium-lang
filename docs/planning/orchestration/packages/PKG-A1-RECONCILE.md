# PKG-A1-RECONCILE: Align runtime `dev` A1 with main PrimRegistry wild:

**WP:** WP-4 follow-on · **Priority:** P0 · **Status:** blocked-merge · **Hub:** mycelium-lang#30

## Problem

Two concurrent host-op architectures:

| Branch / path | Model | Consumers |
|---------------|-------|-----------|
| **main** (`#11` train/gap-closure) | `PrimRegistry` `wild:` via `register_host` / `install_host_ops` (`host.rs`) | sys-host, cli, S-HOST-REGISTRY, std-net host_registry |
| **dev** (A1, runtime#6) | Separate `HostOpRegistry` + `wild` module; **ignores** `PrimRegistry::register("wild:…")` | older A1 PR series |

Merging runtime#6 as-is **breaks** Tier-0 install already on main.

## Goal

One public surface = **S-HOST-REGISTRY** (PrimRegistry). Port valuable A1 content onto main without dual registries.

## Port inventory (from dev → main)

| Item | Keep? | How |
|------|-------|-----|
| Migration diagnostic when someone uses PrimRegistry.register for wild: | yes | soft warn or doc+test on main |
| Fail-closed `read_capped` | yes as **optional** wild name — zipper amends catalog first | implement as PrimFn in sys-host or separate install helper |
| Honest `with_host_floor` | rename to install path already covered by CLI/sys-host | do not dual-path Interpreter |
| HostCapabilities::ffi gate | defer unless zipper decides capability bits are P0 | optional follow-up surface |

## Non-goals

- Dual dispatch (PrimRegistry + HostOpRegistry)
- Blind merge of runtime#6
- *-myc

## Lanes

| Lane | Repo | Role |
|------|------|------|
| L-ZIP | mycelium-lang | amend S-HOST-REGISTRY if new names |
| L-RT | mycelium-runtime | implementer on **main-based** branch only |
| L-ADV | mycelium-lang | adversarial review |

## Success criteria

- [ ] runtime#6 closed or rewritten as main-based PR with no HostOpRegistry dual path
- [ ] sys-host + cli tests still green without code changes (or minimal)
- [ ] Documented one-liner in host.rs that A1 dual registry is rejected

## Kickoff prompt

```
PACKAGE PKG-A1-RECONCILE. Do NOT merge runtime#6.
Surface S-HOST-REGISTRY is law. Port A1 tests/diagnostics onto PrimRegistry mainline only.
Hub #30. Title: train/gap-closure: reconcile A1 onto PrimRegistry wild:
```
