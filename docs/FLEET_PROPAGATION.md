# Fleet propagation (coordinated cross-repo revision bump)

**Measured 2026-07-24.** The numbers here come from
[`scripts/fleet-propagate.py`](../scripts/fleet-propagate.py) resolving live
GitHub state, and are reproducible with `python3 scripts/fleet-propagate.py plan`.

## The gap this closes

`umbrella-draw-in.sh` and `component-draw-in.sh` **validate** the pins in
`components.lock`. Nothing **advances** them. That asymmetry is the whole
problem: work can land green in a component repo and remain invisible to all 45
lock pins and every sibling `rev =` dependency in the fleet.

The measured state of that gap:

| | |
|---|--:|
| Lock pins | 45 |
| Pins at their repo's current `main` | **1** |
| **Stale pins** | **44 (98%)** |
| Commits on `main` not visible to any pin | **314** |
| Sibling git dependency edges | 126 |
| Repos needing a Cargo.toml edit to catch up | **42** |
| **Propagation waves required** | **9** |

39 repos are each *exactly* 7 commits ahead of their pin, 4 are 8 ahead, 1 is 9.
That uniformity means fleet-wide sweeps landed on every `main` and were never
re-pinned — this is not one neglected component, it is the whole train.

## Why it must cascade (and cannot be done in one shot)

The obvious shortcut — rewrite all 126 pins to their dependency's current `main`
in a single sweep — is wrong, and the reason is load-bearing.

Cargo treats the same git URL at two different revs as **two distinct source
ids**. A sibling pinned at two revs therefore puts two copies of that crate in
one build graph, and any type crossing the boundary fails to unify. The fleet
currently satisfies the single-version invariant exactly:

```
$ python3 scripts/fleet-propagate.py check
sibling deps referenced fleet-wide : 27
deps pinned at >1 distinct rev     : 0
OK — single-version invariant holds.
```

All 126 sibling pins agree with `components.lock`, and every sibling resolves to
exactly one rev. **The frozen fleet is coherent — just uniformly stale.** That is
the good failure mode; it means one coordinated advance can move it.

A single-shot rewrite would transiently violate that invariant. If
`mycelium-l1` advances its `mycelium-value` pin to value's current `main`, that
commit of value still pins `mycelium-core` at the *old* rev — while `l1` has
already advanced core. Two revs of `mycelium-core`, one graph, broken build.

So propagation proceeds in **waves**. A repo is in wave *N* because its
dependency's HEAD only moves once that dependency's wave-*(N−1)* PR merges.
Wave count equals the depth of the dependency DAG, which is **9**.

That number is the honest cost of the current structure, and it is what makes
hand-propagation unsustainable: 9 *sequential* merge rounds across 42 repos.

## Shape of the DAG

46 repos, 126 edges, **0 cycles**, 0 pin conflicts. Fan-in is concentrated:

| Component | dependents |
|---|--:|
| `mycelium-core` | **36** |
| `mycelium-std-core` | 17 |
| `mycelium-runtime` | 12 |
| `mycelium-l1` | 10 |
| `mycelium-value` | 9 |
| `mycelium-proj` | 8 |

Because `mycelium-core` has fan-in 36, any core change is a fleet-wide event.
Wave sizes: 6 → 12 → 9 → 2 → 3 → 5 → 4 → 1, ending at
`mycelium-std-conformance`, which alone needs 16 pin bumps.

## Usage

```bash
# 1. Verify the invariant before touching anything. Refuses to plan if broken.
python3 scripts/fleet-propagate.py check

# 2. See exactly what would change. Read-only.
python3 scripts/fleet-propagate.py plan

# 3. Open one PR per repo for the current wave.
python3 scripts/fleet-propagate.py apply --wave 1 --train v0.465.0

# 4. Merge that wave, then RE-PLAN and repeat until plan reports no edits.
# 5. Finally re-pin the umbrella:
python3 scripts/fleet-propagate.py lock --write
```

### The one correctness trap

**Target revs are only exact for the next wave.** Merging a wave moves the HEAD
of every repo in it, so each subsequent wave must be re-resolved against live
state. Always run `apply --wave 1` off a *fresh* `plan`; replaying a cached
`--state` will pin revs that are no longer tips. The tool prints this warning
whenever a plan needs more than one wave.

### Safety properties

- Rewrites **only** 40-char `rev` values on `tzervas/*` git dependencies.
  Version requirements, features, path deps and third-party deps are untouched —
  verified by diffing manifests with all rev values masked, which comes back
  byte-identical.
- Never pushes to a protected branch and never merges. `apply` only creates a
  working branch and opens a PR.
- `--dry-run` performs the clone and rewrite and reports what it would commit.
- Resolves from live GitHub state, so a stale local checkout cannot produce a
  wrong plan.

## Sequencing note — do not propagate first

Three execution-path landings (**A1** host-op registry in `mycelium-runtime`,
**B1**/**B2** LLVM `Match`/`FixGroup` lowering in `mycelium-codegen`) are merged
to those repos' **`dev`** branches, not `main`:

| Repo | `dev` ahead of `main` |
|---|--:|
| `mycelium-codegen` | 5 commits (B1 + B2) |
| `mycelium-runtime` | 3 commits (A1) |

Propagation targets `main`. Running it now would advance the whole fleet to
`main` revisions that **still do not contain A1/B1/B2** — a 9-wave cascade that
propagates everything except the work the cascade was meant to deliver, and
which would then have to be run a second time.

**Correct order:** land `dev` → `main` for `mycelium-codegen` and
`mycelium-runtime` first, then propagate once.
