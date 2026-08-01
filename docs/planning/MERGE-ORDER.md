# WP-1 fan-out merge order + re-pin runbook

**Hub:** [mycelium-lang#30](https://github.com/tzervas/mycelium-lang/issues/30)  
**Package:** PKG-WP1-FANOUT  
**Decision:** **merge-then-repin** for docs + CI fleet-tier fan-outs  
**Inventory snapshot:** 2026-08-01 (UTC) — re-check CI before any merge  
**Lane:** L-REPIN prep / WP-1 (umbrella-only docs)

## Rules (non-negotiable)

1. **Do not merge red PRs.** Re-run / fix CI first.  
2. **Do not re-pin** `components.lock` until **both** fan-out trains below are fully merged (or explicitly deferred with hub note).  
3. After full merge, re-pin only via a **measured** full-scope draw-in (`MODE=check+test`, `FAIL_FAST=0`, all **45** Rust pins).  
4. Prefer **CI tier labels before docs** within a repo when both exist, so compile jobs stop landing on `micro` workers.

## Trains in scope

| Train | Title pattern | Hub anchors |
|-------|---------------|-------------|
| **CI fleet tier** | `ci(fleet): pin runner tier labels so compile jobs cannot land on micro` | [mycelium-lang#25](https://github.com/tzervas/mycelium-lang/pull/25) |
| **Docs GAP-STATUS** | `docs: GAP-STATUS.md → umbrella expressibility roadmap` (+ umbrella roadmap) | [mycelium-lang#26](https://github.com/tzervas/mycelium-lang/pull/26) |

Out of scope for this WP (do not block re-pin wait on them unless hub says so): WP-0/WP-4/ORCH PRs (`train/gap-closure: …`, materializer, HostCallRegistry, zipper packages).

---

## Exact merge order

### Phase A — green CI only (mergeable now)

Merge in this sequence when checks stay green:

| Step | PR | Base | Train | Why this step |
|------|----|------|-------|---------------|
| A1 | [mycelium-lang#25](https://github.com/tzervas/mycelium-lang/pull/25) | `dev` | CI tier | Umbrella fleet routing pin (then promote `dev`→`main` per branch policy) |
| A2 | [mycelium-codegen#11](https://github.com/tzervas/mycelium-codegen/pull/11) | `dev` | CI tier | Member CI tier, green |
| A3 | [mycelium-l1#11](https://github.com/tzervas/mycelium-l1/pull/11) | `dev` | CI tier | Member CI tier, green |
| A4 | [mycelium-runtime#8](https://github.com/tzervas/mycelium-runtime/pull/8) | `dev` | CI tier | Member CI tier, green |
| A5 | [mycelium-std-sys#7](https://github.com/tzervas/mycelium-std-sys/pull/7) | `main` | CI tier | Member CI tier, green |
| A6 | [mycelium-std-runtime#6](https://github.com/tzervas/mycelium-std-runtime/pull/6) | `main` | CI tier | Member CI tier, green |
| A7 | [mycelium-lang#26](https://github.com/tzervas/mycelium-lang/pull/26) | `main` | Docs (umbrella roadmap) | Umbrella docs train anchor |

> **Branch note:** Several CI-tier heads target `dev`. If `dev` is not the default, land on `dev` then open/merge the normal `dev`→default promotion; do not leave tier labels only on a dead branch.

### Phase B — blocked (red fleet CI) — re-run after A, then merge when green

Most reds are **fleet job timeouts** (`detect stack` / `gitleaks` / `trivy` at ~24h), not product `check` failures. Still **blocked until green**.

#### B1 — remaining CI tier (merge CI before docs when both open on same repo)

| PR | Base | Note |
|----|------|------|
| [mycelium-core#7](https://github.com/tzervas/mycelium-core/pull/7) | `main` | red fleet |
| [mycelium-fmt#6](https://github.com/tzervas/mycelium-fmt/pull/6) | `main` | red fleet |
| [mycelium-std-core#5](https://github.com/tzervas/mycelium-std-core/pull/5) | `main` | red fleet |
| [mycelium-std-error#5](https://github.com/tzervas/mycelium-std-error/pull/5) | `main` | red fleet |
| [mycelium-std-io#7](https://github.com/tzervas/mycelium-std-io/pull/7) | `main` | red fleet |
| [mycelium-std-math#5](https://github.com/tzervas/mycelium-std-math/pull/5) | `dev` | red fleet |
| [mycelium-transpile#6](https://github.com/tzervas/mycelium-transpile/pull/6) | `main` | red fleet |
| [mycelium-value#6](https://github.com/tzervas/mycelium-value/pull/6) | `main` | red fleet |

#### B2 — docs GAP-STATUS members (after same-repo CI tier if any)

Alphabetical by repo (stable order for agents); skip if still red:

| PR | Base |
|----|------|
| [mycelium-bench#5](https://github.com/tzervas/mycelium-bench/pull/5) | `main` |
| [mycelium-build#5](https://github.com/tzervas/mycelium-build/pull/5) | `main` |
| [mycelium-check#5](https://github.com/tzervas/mycelium-check/pull/5) | `main` |
| [mycelium-cli#5](https://github.com/tzervas/mycelium-cli/pull/5) | `main` |
| [mycelium-codegen#12](https://github.com/tzervas/mycelium-codegen/pull/12) | `main` |
| [mycelium-core#8](https://github.com/tzervas/mycelium-core/pull/8) | `main` |
| [mycelium-doc#5](https://github.com/tzervas/mycelium-doc/pull/5) | `main` |
| [mycelium-fmt#7](https://github.com/tzervas/mycelium-fmt/pull/7) | `main` |
| [mycelium-l1#12](https://github.com/tzervas/mycelium-l1/pull/12) | `main` |
| [mycelium-lang-myc#4](https://github.com/tzervas/mycelium-lang-myc/pull/4) | `main` |
| [mycelium-lint#5](https://github.com/tzervas/mycelium-lint/pull/5) | `main` |
| [mycelium-lsp#5](https://github.com/tzervas/mycelium-lsp/pull/5) | `main` |
| [mycelium-proj#5](https://github.com/tzervas/mycelium-proj/pull/5) | `main` |
| [mycelium-runtime#9](https://github.com/tzervas/mycelium-runtime/pull/9) | `main` |
| [mycelium-sec#5](https://github.com/tzervas/mycelium-sec/pull/5) | `main` |
| [mycelium-spore#5](https://github.com/tzervas/mycelium-spore/pull/5) | `main` |
| [mycelium-std-collections#5](https://github.com/tzervas/mycelium-std-collections/pull/5) | `main` |
| [mycelium-std-core#6](https://github.com/tzervas/mycelium-std-core/pull/6) | `main` |
| [mycelium-std-error#6](https://github.com/tzervas/mycelium-std-error/pull/6) | `main` |
| [mycelium-std-fs#5](https://github.com/tzervas/mycelium-std-fs/pull/5) | `main` |
| [mycelium-std-io#8](https://github.com/tzervas/mycelium-std-io/pull/8) | `main` |
| [mycelium-std-runtime#7](https://github.com/tzervas/mycelium-std-runtime/pull/7) | `main` |
| [mycelium-std-spore#6](https://github.com/tzervas/mycelium-std-spore/pull/6) | `main` |
| [mycelium-std-sys#8](https://github.com/tzervas/mycelium-std-sys/pull/8) | `main` |
| [mycelium-std-text#5](https://github.com/tzervas/mycelium-std-text/pull/5) | `main` |
| [mycelium-transpile#7](https://github.com/tzervas/mycelium-transpile/pull/7) | `main` |
| [mycelium-value#7](https://github.com/tzervas/mycelium-value/pull/7) | `main` |

### Phase C — already merged

| Train | Count (2026-08-01 snapshot) |
|-------|-----------------------------|
| CI tier (mycelium-*) | **0** |
| Docs GAP-STATUS (mycelium-*) | **0** |

---

## Phase D — measured re-pin (WP-2; only after A+B complete)

**Do not run re-pin yet** if any Phase B PR remains open/red.

### Preconditions

- [ ] All Phase A merged  
- [ ] All Phase B CI-tier PRs merged or closed with hub rationale  
- [ ] All Phase B docs GAP-STATUS PRs merged or closed with hub rationale  
- [ ] Fleet can schedule `large` for cargo (tier labels landed on workers that need compile)  
- [ ] Operator host has `git`, `cargo`, network to `github.com/tzervas/*`

### Commands (document only — full 45 not expected in agent sandbox)

```bash
# 1) Fresh umbrella on default branch after fan-outs landed
git clone https://github.com/tzervas/mycelium-lang.git
cd mycelium-lang
git checkout main   # or post-merge tip

# 2) Advance pins to component default-branch HEADs that contain the merged fan-outs
#    (implementation detail: existing pin-update tooling if present; else per-line
#     components.lock update with rev + tree= content hash). Prefer one PR.

# 3) Full measured draw-in — all 45 pins, continue on failure for complete report
MODE=check+test FAIL_FAST=0 REPORT_JSONL=draw-in-wp1-full.jsonl \
  bash scripts/umbrella-draw-in.sh

# 4) Optional container cross-check (subset OK for smoke; full 45 is host gate)
# MODE=check+test FAIL_FAST=0 PIN_LIMIT=5 bash scripts/draw-in-container.sh

# 5) Only if ok == 45 (or hub-approved exceptions): open umbrella PR
#    updating components.lock header + pin lines; attach REPORT_JSONL summary.
```

### Success criteria for re-pin PR

| Gate | Requirement |
|------|-------------|
| Scope | All **45** Rust pins in `components.lock` exercised |
| Mode | `MODE=check+test` |
| Fail policy | `FAIL_FAST=0` (full report) then **zero unexpected fails** before claiming green |
| Evidence | `REPORT_JSONL` (or equivalent) attached on hub #30 + re-pin PR |
| Honesty | Header comment in `components.lock` only claims what the sweep measured |

### Sandbox limitation

Agent/sandbox environments typically **cannot** complete a full 45-pin draw-in (time, network, cargo cache). Operators run Phase D on a fleet host or CI `draw-in linux-x64-host` job after pins advance.

---

## Inventory summary (snapshot)

| Bucket | CI tier | Docs GAP / umbrella | Total |
|--------|---------|---------------------|-------|
| Mergeable now (green) | 6 | 1 (`#26`) | **7** |
| Blocked (red CI) | 8 | 27 | **35** |
| Already merged | 0 | 0 | **0** |
| **Open total** | **14** | **28** | **42** |

Hub anchors **#25** (CI) and **#26** (docs) are both **MERGEABLE / CLEAN** at snapshot time.

---

## Operator checklist

1. Re-query `gh pr checks` immediately before each merge.  
2. Merge Phase A only.  
3. Bulk re-run failed fleet workflows on Phase B (or push empty commit) once tier labels + fleet capacity are healthy.  
4. Merge Phase B as greens appear (CI before docs per repo).  
5. Comment progress on hub #30.  
6. Only then execute Phase D re-pin + open components.lock PR.
