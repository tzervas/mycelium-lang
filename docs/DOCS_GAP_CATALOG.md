# Component documentation gap catalog (Rust train)

**Measured 2026-07-24** across all 46 component repos checked out under a common
root. Every number here is produced by [`scripts/docs-gap-survey.py`](../scripts/docs-gap-survey.py)
and is reproducible:

```bash
COMPONENTS_ROOT=/path/to/components python3 scripts/docs-gap-survey.py
# or
python3 scripts/docs-gap-survey.py /path/to/components
```

Per the honesty rule in [`components.lock`](../components.lock): this document
reports what the survey **measured**. Nothing here is asserted from inspection of
a sample and generalised.

## Why this document exists

[`COMPONENT_READINESS.md`](COMPONENT_READINESS.md) defines readiness as gates
**A–F**: standalone build, standalone test, fleet CI, spec alignment, dual-mode
surface, native twin. Those gates are real and enforced by draw-in.

**None of them is a documentation gate.** A component can be fully "ready" by
A–F today while being undiscoverable to any consumer who is not already inside
the program. That is the structural gap this catalog records.

## Headline findings

| Finding | Count | Severity |
|---|--:|---|
| READMEs that are the unmodified extraction stub (≤27 lines) | **44 / 46** | **G1 — high** |
| Components with no `## Usage` / getting-started section | **46 / 46** | **G1 — high** |
| Components with no install / `[dependencies]` snippet | **46 / 46** | **G1 — high** |
| Large crates with **zero** crate-level `//!` docs | **6** | **G2 — high** |
| Undocumented public items fleet-wide | **355 / 3218 (11%)** | **G3 — medium** |
| Components with no `#![warn(missing_docs)]` | **46 / 46** | **G4 — medium** |
| Components with no `CONTRIBUTING.md` | **46 / 46** | **G5 — medium** |
| Components with no `CHANGELOG.md` | **45 / 46** | **G6 — low** |
| Components with no `examples/` | **45 / 46** | **G7 — low** |

Counterpoint, and it matters: **rustdoc coverage of public items is already
strong** — 89% fleet-wide, with 15 components at 100%. The deficit is *not*
API-reference discipline. It is that nothing above the item level explains what
a component is, why it exists, or how to start using it.

---

## G1 — READMEs are extraction stubs, and one of their claims is now false

44 of 46 READMEs are the mechanical Phase-D extraction template. They differ only
in component name and source path. The template documents *provenance*, not the
component:

```markdown
# mycelium-std-io

<!-- FLEET-BADGES ... -->

Component extracted from monorepo `tzervas/mycelium`
at archive tip `aad96b7a...`.

| Field | Value |
| **Program** | PROGRAM-SELFHOST-DECOMPOSE-2026-07-17 Phase D |
| **Source paths** | crates/mycelium-std-io |
...
## Build
MSRV 1.96.1. Path deps on sibling components may still point at monorepo-relative
paths — wire git deps in a follow-up (FLAG).
```

A reader learns where the code came from and nothing about what it does.

**The `(FLAG)` line is stale and should be removed, not just improved.** The
survey checked it directly:

| Sibling dependency style | Count |
|---|--:|
| `path = "../…"` (the state the FLAG warns about) | **0** |
| `git = "https://github.com/tzervas/…"` pinned by `rev =` | **104** |
| pinned by `tag =` | 0 |
| floating `branch =` | 0 |
| unpinned | 0 |

All 104 sibling deps across 36 repos are SHA-pinned git deps. The follow-up the
FLAG asks for was completed. Under the honesty rule a README that warns of a
resolved defect is itself a documentation defect — it understates readiness.

**The exception worth copying:** `mycelium-lang`'s own README (82 lines) is good.
It states the repo's role in one sentence, carries an honest CI-surface table
that distinguishes product gates from fleet hygiene, and links the docs set. It
is the obvious template source for the component READMEs.

## G2 — Six large crates have no crate-level `//!` documentation

These are the crates a newcomer opens first, and `cargo doc` renders them with an
empty front page:

| Component | public items | rustdoc % of items | crate-level `//!` lines |
|---|--:|--:|--:|
| `mycelium-codegen` | 390 | 91% | **0** |
| `mycelium-core` | 363 | 83% | **0** |
| `mycelium-runtime` | 262 | 94% | **0** |
| `mycelium-l1` | 261 | 94% | **0** |
| `mycelium-value` | 164 | 91% | **0** |
| `mycelium-doc` | 116 | 85% | **0** |

Together that is **1,556 public items — 48% of the fleet's entire public
surface — behind a blank crate page.** By contrast the 25 `mycelium-std-*` crates
that have crate docs average 80 lines of `//!` and read well. The gap is concentrated, not diffuse,
which makes it cheap to close: six files.

## G3 — 355 undocumented public items, concentrated in a short tail

Fleet-wide coverage is 89%. The deficit is not evenly spread:

| Component | coverage | undocumented | of total public |
|---|--:|--:|--:|
| `mycelium-transpile` | 64% | **68** | 188 |
| `mycelium-core` | 83% | **61** | 363 |
| `mycelium-std-runtime` | 83% | 24 | 138 |
| `mycelium-lsp` | 86% | 22 | 160 |
| `mycelium-doc` | 85% | 17 | 116 |
| `mycelium-runtime` | 94% | 17 | 262 |

The top two account for **129 of 355 (36%)**. `mycelium-transpile` is the clear
outlier and the only component below 70%.

## G4 — No component can detect doc regression

No component sets `#![warn(missing_docs)]` or `#![deny(missing_docs)]`. Today's
89% coverage is therefore unenforced: it can decay to any value without a single
CI signal. Given that fleet CI already gates `cargo check/test`, `gitleaks` and
`trivy`, docs are the one quality axis with measurement but no ratchet.

## G5–G7 — Supporting files

- **G5 `CONTRIBUTING.md`: absent in all 46.** The program's review standard
  (honesty tags, append-only ADR/RFC discipline, "which FR/NFR/VR/SC and how
  verified") is enforced in review but written down in no component repo. An
  outside contributor cannot discover it.
- **G6 `CHANGELOG.md`: present only in `mycelium-lang`.** Every component has a
  release workflow, so changelogs can be generated rather than hand-written.
- **G7 `examples/`: present only in `mycelium-lsp`** (2 examples). 32 of 46 do
  have a `docs/*.md`, usually a single design note.

## Two components are empty shells

`mycelium-lang` (umbrella — expected, it re-exports) and
**`mycelium-std-conformance`** (0 public items, 0 docs, 0 `docs/*.md`). The
latter is pinned in `components.lock` and carries a full CI surface for no
content. It needs either an implementation plan or an explicit "reserved" note.

---

## Per-component detail

Sorted by public-item count. `//!` is crate-level doc lines on the primary
`lib.rs`; **bold** marks a gap.

| Component | README | Usage | Install | `//!` | rustdoc % | undoc'd | docs/ | examples |
|---|--:|:-:|:-:|--:|--:|--:|--:|--:|
| `mycelium-codegen` | 26 | **no** | **no** | **0** | 91% | 37 | 0 | 0 |
| `mycelium-core` | 26 | **no** | **no** | **0** | 83% | 61 | 1 | 0 |
| `mycelium-runtime` | 26 | **no** | **no** | **0** | 94% | 17 | 1 | 0 |
| `mycelium-l1` | 26 | **no** | **no** | **0** | 94% | 15 | 2 | 0 |
| `mycelium-transpile` | 26 | **no** | **no** | 33 | 64% | 68 | 2 | 0 |
| `mycelium-value` | 26 | **no** | **no** | **0** | 91% | 14 | 0 | 0 |
| `mycelium-lsp` | 26 | **no** | **no** | 8 | 86% | 22 | 0 | 2 |
| `mycelium-std-runtime` | 26 | **no** | **no** | 112 | 83% | 24 | 1 | 0 |
| `mycelium-doc` | 26 | **no** | **no** | **0** | 85% | 17 | 0 | 0 |
| `mycelium-bench` | 26 | **no** | **no** | 42 | 93% | 8 | 0 | 0 |
| `mycelium-std-fs` | 26 | **no** | **no** | 68 | 93% | 5 | 1 | 0 |
| `mycelium-std-testing` | 26 | **no** | **no** | 78 | 95% | 3 | 1 | 0 |
| `mycelium-std-iter` | 26 | **no** | **no** | 97 | 87% | 7 | 1 | 0 |
| `mycelium-std-time` | 26 | **no** | **no** | 96 | 100% | 0 | 1 | 0 |
| `mycelium-proj` | 26 | **no** | **no** | 23 | 92% | 4 | 0 | 0 |
| `mycelium-build` | 26 | **no** | **no** | 20 | 96% | 2 | 0 | 0 |
| `mycelium-std-collections` | 26 | **no** | **no** | 119 | 89% | 5 | 1 | 0 |
| `mycelium-std-recover` | 26 | **no** | **no** | 72 | 85% | 7 | 1 | 0 |
| `mycelium-std-sys` | 26 | **no** | **no** | 58 | 85% | 7 | 2 | 0 |
| `mycelium-spore` | 26 | **no** | **no** | 15 | 100% | 0 | 0 | 0 |
| `mycelium-std-spore` | 26 | **no** | **no** | 76 | 91% | 4 | 1 | 0 |
| `mycelium-std-ternary` | 26 | **no** | **no** | 66 | 91% | 4 | 1 | 0 |
| `mycelium-std-text` | 26 | **no** | **no** | 91 | 91% | 4 | 1 | 0 |
| `mycelium-std-math` | 42 | **no** | **no** | 88 | 93% | 3 | 1 | 0 |
| `mycelium-std-io` | 26 | **no** | **no** | 111 | 89% | 4 | 2 | 0 |
| `mycelium-std-content` | 26 | **no** | **no** | 87 | 87% | 4 | 1 | 0 |
| `mycelium-std-dense` | 26 | **no** | **no** | 89 | 100% | 0 | 1 | 0 |
| `mycelium-std-error` | 26 | **no** | **no** | 75 | 93% | 2 | 1 | 0 |
| `mycelium-std-numerics` | 26 | **no** | **no** | 61 | 96% | 1 | 1 | 0 |
| `mycelium-std-rand` | 26 | **no** | **no** | 84 | 100% | 0 | 1 | 0 |
| `mycelium-check` | 26 | **no** | **no** | 14 | 100% | 0 | 0 | 0 |
| `mycelium-cli` | 26 | **no** | **no** | 30 | 100% | 0 | 0 | 0 |
| `mycelium-std-cmp` | 26 | **no** | **no** | 70 | 100% | 0 | 1 | 0 |
| `mycelium-std-vsa` | 26 | **no** | **no** | 56 | 79% | 4 | 1 | 0 |
| `mycelium-std-fmt` | 26 | **no** | **no** | 94 | 100% | 0 | 1 | 0 |
| `mycelium-std-swap` | 26 | **no** | **no** | 58 | 100% | 0 | 1 | 0 |
| `mycelium-lint` | 26 | **no** | **no** | 21 | 100% | 0 | 0 | 0 |
| `mycelium-fmt` | 26 | **no** | **no** | 54 | 100% | 0 | 1 | 0 |
| `mycelium-std-core` | 26 | **no** | **no** | 59 | 92% | 1 | 1 | 0 |
| `mycelium-sec` | 26 | **no** | **no** | 20 | 100% | 0 | 0 | 0 |
| `mycelium-cli-common` | 26 | **no** | **no** | 27 | 100% | 0 | 0 | 0 |
| `mycelium-std-select` | 26 | **no** | **no** | 82 | 100% | 0 | 1 | 0 |
| `mycelium-std-diag` | 27 | **no** | **no** | 56 | 83% | 1 | 1 | 0 |
| `mycelium-std-sys-host` | 26 | **no** | **no** | **0** | 100% | 0 | 1 | 0 |
| `mycelium-lang` | 82 | **no** | **no** | **0** | 0% | 0 | 4 | 0 |
| `mycelium-std-conformance` | 26 | **no** | **no** | **0** | 0% | 0 | 0 | 0 |
---

## Proposed remediation

Ordered by value per unit of effort. Each stage is independently shippable.

### Stage 1 — README rewrite (closes G1) · 46 mechanical PRs

Extend the README template from provenance-only to a real front page, keeping the
existing badge block and provenance table (moved below the fold):

1. **One-sentence role statement** — what this component is, in the language of
   the program.
2. **Where it sits** — its direct sibling deps and dependents, generated from
   `components.lock`, so the fleet graph is navigable from any node.
3. **Install** — the exact `git = …, rev = …` snippet, generated from the lock.
4. **Usage** — a compiling snippet; for `mycelium-std-*` the crate-level `//!`
   example already exists and can be lifted verbatim.
5. **Provenance table** — retained, demoted, **with the stale `(FLAG)` line
   deleted**.

Items 2 and 3 are derivable from `components.lock`, so most of each README is
generated rather than authored. That is what makes 46 repos tractable.

### Stage 2 — Crate-level `//!` for the six blank crates (closes G2)

Six files. Highest reader impact per line in the whole catalog: it converts 48%
of the public surface from a blank `cargo doc` landing page into a navigable one.
Not mechanical — each needs a genuine architectural summary.

### Stage 3 — `missing_docs` ratchet (closes G4, protects G3)

Add `#![warn(missing_docs)]` to every component, and `#![deny(missing_docs)]` to
the 15 already at 100% so they cannot regress. Then close the G3 tail
(`mycelium-transpile` first, at 64%), promoting `warn` → `deny` per component as
it reaches 100%. This makes coverage a ratchet instead of a snapshot.

### Stage 4 — `CONTRIBUTING.md` + changelog generation (closes G5, G6)

One shared `CONTRIBUTING.md`, written once and distributed by the same fleet
script. Changelogs generated from the existing release workflow rather than
authored.

### Recommended: make docs a readiness gate

Add a **gate G — documentation** to `COMPONENT_READINESS.md`, so this class of
gap cannot silently reopen:

| Layer | Gate |
|-------|------|
| **G. Documentation** | README has role + install + usage; crate-level `//!` present; `cargo doc` builds with no warnings; `missing_docs` at `warn` or stricter |

Without gate G, Stages 1–4 are a one-time cleanup that decays. With it, they are
a standard.

## Decisions required before Stage 1 opens PRs

1. **Blast radius** — 46 separate per-repo PRs (reviewable, slow) vs batching by
   family (`std-*` / compiler / tooling) into ~4 PRs (fast, coarser review)?
2. **Generated vs authored** — accept generated dependency-graph and install
   sections as the default, with hand-authored usage only where the `//!` example
   cannot be lifted?
3. **`missing_docs` severity** — `warn` fleet-wide first, or go straight to
   `deny` on the 15 components already at 100%?
4. **`mycelium-std-conformance`** — implement, or mark reserved and note it in
   the lock?
5. **Gate G** — adopt into `COMPONENT_READINESS.md` now, or after Stages 1–3 land?
