# PKG-ORCH-WORKFLOWS: ap-workflows: action pins composition + train-lane reusable

**WP:** ORCH · **Priority:** P0 · **Status:** ready  
**Hub:** https://github.com/tzervas/mycelium-lang/issues/30  
**Title prefix:** `train/gap-closure:`

## Goal

Centralize GitHub Actions major pins in pins/actions.yml; document compose-down; add reusable train-lane package validation; keep rootless/minimal as late image concern.

## Non-goals

- Replacing all caller workflows in one PR
- Building all base images now

## Surfaces

- `S-ECOSYSTEM-LOCK`

## Lanes

| Lane | Repo | Role | Depends |
|------|------|------|---------|
| L-PINS | tzervas/ap-workflows | ci | — |

## Success criteria (package)

- [ ] pins/actions.yml merged
- [ ] checker in self-test or ci-checker

## Adversarial checklist

- [ ] Majors only at pin file; minors via dependabot
- [ ] No secret in pins
- [ ] Self-hosted only where policy says

## Kickoff prompt (copy to agent)

```
PACKAGE PKG-ORCH-WORKFLOWS. You work only in tzervas/ap-workflows.
Create pins/actions.yml as single source of stable major versions for all uses: actions.
Add a checker that greps workflows for uses: and verifies major matches pins (allow local ./).
Document: callers compose via uses: tzervas/ap-workflows/...@v0.1; image rootless/minimal applied in image build jobs late, not at reusable CI top.
Self-hosted fleet. No apt-get in CI scripts.
Hub mycelium-lang#30. Title train/gap-closure: pins composition.
```

## Blocked by / unblocks

- **Blocked by:** —
- **Unblocks:** maintainable fleet composition, agent CI consistency
