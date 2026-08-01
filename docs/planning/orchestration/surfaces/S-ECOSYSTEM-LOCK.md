# Surface S-ECOSYSTEM-LOCK — CI train control

**Status:** FREEZE (WP-0)  
**Homes:** `ap-workflows` · `mycelium-lang` (`components.lock`, `docs/PACKAGE_REPO_MAP.json`)

## workflow_call inputs (reusable-ci-rust)

| Input | Type | Default | Semantics |
|-------|------|---------|-----------|
| `ecosystem-lock-ref` | string | `""` | Git ref of mycelium-lang; empty = skip materialize |
| `dep-overrides` | string JSON | `{}` | lock-pin → full SHA; never PR title/body |
| `train-version` | string | `""` | Label for summaries |

## Precedence

1. `dep-overrides`
2. `components.lock` at lock-ref
3. Crate `Cargo.toml` git rev

## Package map

`docs/PACKAGE_REPO_MAP.json` — package name → repo pin (multi-crate aware).

## Materializer CLI

```bash
python3 scripts/materialize-ecosystem-deps.py \
  --lock-ref main \
  --overrides '{"mycelium-runtime":"<sha>"}' \
  --out .cargo/config.toml
```

Writes Cargo `[patch."https://github.com/tzervas/<repo>"]` tables.

## Action pins composition

All `uses:` majors come from `ap-workflows/pins/actions.yml` (compose-down). Callers pin `ap-workflows@v0.1` moving tag.
