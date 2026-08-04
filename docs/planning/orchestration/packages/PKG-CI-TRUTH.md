# PKG-CI-TRUTH — CI truthfulness: stop reporting green on work that never ran

| Field | Value |
|---|---|
| **WP** | WP-13 |
| **Priority** | P0 |
| **Status** | frozen (PR #49 merged 2026-08-04) |
| **Hub** | https://github.com/tzervas/mycelium-lang/issues/48 |
| **Effort** | XL |
| **Requires re-pin** | no |

## Goal

Close gaps (9)(10)(11): stop the fleet from reporting green on work that never ran. Sequence behind ap-workflows PR #30 (merged) + its image republish, then: (a) swap all 45 `*-myc` `placeholder` CI jobs for a real `myc-check` gate via reusable-ci-mycelium.yml (project-dir: lib, deny-warnings: true, acknowledge-not-adopted: true) targeting `dev`; (b) migrate the 49 non-umbrella real-CI Rust component repos (of the 50 REAL-classified repos, excluding the umbrella `mycelium-lang`) from bespoke ci.yml onto reusable-ci-rust.yml with ecosystem-lock-ref wired; (c) ship the missing reusable-train-lane.yml (validates a work-package JSON against schemas/work-package.schema.json and comments the linked hub issue) in ap-workflows; (d) make mycelium-bench's CI actually invoke its own `cargo run --release --bin bench` harness and assert a non-trivial report, so the fleet's `bench=run must FAIL_ENV without a device` posture has something real to gate; (e) produce a measured, human-reviewable verdict on the net-host feature-gate leak (does a default `mycelium-cli` build carry live `http_request` registration despite `net-host` being off?) plus a regression check that makes the answer machine-checkable going forward.

## Non-goals

- Writing the real `build`/`test` steps inside reusable-ci-mycelium.yml — those are deliberate loud PLACEHOLDER failures blocked on the DN-50 accept<->instantiate gap (language gaps 1-8); do not flip `depth` past `check` for any `*-myc` caller in this package.
- Fixing the 13+ myc-check findings the newly-real gate will surface across the *-myc train (44% trace to gap 1, no import/module mechanism) — this package makes the debt VISIBLE, not paid off.
- Re-deriving or fixing the root cause of the net-host leak — (e) delivers measurement + verdict + a regression trip-wire, not a guessed fix, unless the human verdict explicitly authorizes one.
- Migrating `mycelium-lang` / `mycelium-lang-myc` (the umbrella monorepo): they already run a real, different job model (`lock-format` + OS/arch draw-in matrix, self-hosted, `dev`+`main`+schedule triggers) that this package's caller templates do not fit — flagged for a separate human decision, not touched here.
- The general fleet-wide `fleet-ci.yml`/`fleet-security.yml` centralization (detect-stack/gitleaks/trivy) — that is a separate, already-in-flight track (`scripts/rollout-callers.sh`) unrelated to the Mycelium-specific reusables this package adopts.
- Adding GPU-backed benchmark cases to mycelium-bench, or deciding whether any Mycelium backend needs a GPU device at all — out of scope; flagged unknown for human call in lane risk notes.
- Publishing to crates.io (ADR-018, permanently off) or building the mycelium-spore registry integration.

## Surfaces (frozen by L-ZIP before any implementer starts)

- [`S-MYC-CI-CALLER`](../surfaces/S-MYC-CI-CALLER.md) — tzervas/ap-workflows
- [`S-RUST-CI-CALLER`](../surfaces/S-RUST-CI-CALLER.md) — tzervas/ap-workflows
- [`S-TRAIN-LANE`](../surfaces/S-TRAIN-LANE.md) — tzervas/ap-workflows
- [`S-BENCH-GATE`](../surfaces/S-BENCH-GATE.md) — tzervas/mycelium-bench
- [`S-NET-HOST-CHECK`](../surfaces/S-NET-HOST-CHECK.md) — tzervas/mycelium-cli

## Lanes

| Lane | Repo | Role | Done when |
|---|---|---|---|
| `L-ZIP` | tzervas/mycelium-lang | zipper | All surface files merged; no implementer lane starts before this. |
| `L-TZERVAS-AP-WORKFLOWS` | tzervas/ap-workflows | implementer | PR #30 shows merged (not just mergeable) via `gh pr view 30 -R tzervas/ap-workflows --json state` = MERGED. `gh run list -R tzervas/ap-workflows -w image-runner |
| `L-TZERVAS-MYC-45-REPOS` | tzervas/*-myc (45 repos: mycelium-bench-myc, mycelium-build- | implementer | `gh api` scan of all 45 repos' default workflow file shows zero jobs literally named `placeholder` and zero `ls -la lib || true` / `echo "myc-check optional..." |
| `L-TZERVAS-49-REAL-COMP` | tzervas/<49 real component repos> (mycelium-bench, mycelium- | implementer | `gh api` scan shows zero of the 49 repos still carry a hand-written `cargo fmt --check`/`cargo clippy .. -D warnings`/`cargo test` sequence directly in .github/ |
| `L-TZERVAS-MYCELIUM-BEN` | tzervas/mycelium-bench | implementer | A `dev`-targeting CI run produces and uploads `reports/latest-report.md`/`.json` with `run.cases` length > 0. A deliberately-emptied corpus (tested once locally |
| `L-TZERVAS-MYCELIUM-CLI` | tzervas/mycelium-cli | implementer | `docs/NET-HOST-GATE-VERDICT.md` exists, is merged, and contains: (1) raw `cargo tree` output for a default-feature build, (2) the binary-inspection command and  |

## Success criteria

- [ ] ap-workflows PR #30 is merged and `ghcr.io/tzervas/ap-workflows/runner-base:latest` provably contains a static myc-check (verified post-merge, not inferred from the PR description).
- [ ] `gh api` (or an equivalent scripted scan) over all 95 `tzervas/mycelium*` repos finds zero jobs literally named `placeholder` outside of mycelium-lang/mycelium-lang-myc, which are explicitly excluded and separately flagged.
- [ ] All 45 former-`placeholder` repos' CI job reports a real myc-check exit code on both push and pull_request against `dev`; at least one spot-checked repo (mycelium-core-myc) reproduces the previously-measured exit 3 / 13 findings.
- [ ] Zero of the 49 real component repos (excluding the umbrella) still hand-roll `cargo fmt/clippy/test` in their own workflow file; all compose off `tzervas/ap-workflows/.github/workflows/reusable-ci-rust.yml@v0.1`.
- [ ] `dev` branch protection on every migrated repo requires the new `<caller>/check` context; `main` branch protection requires nothing, matching the 2026-08-01 decision — checkable via `gh api repos/{o}/{r}/branches/{b}/protection`.
- [ ] `reusable-train-lane.yml` exists in ap-workflows, is invoked by a new caller in mycelium-lang on changes under docs/planning/orchestration/packages/**, and its self-test demonstrates both a pass (clean fixture) and a fail (fixture missing a required schema field).
- [ ] mycelium-bench's CI produces `reports/latest-report.json` with `run.cases` length > 0 on every `dev`-targeting run, and this was proven non-vacuous by a reverted throwaway commit that emptied the corpus and observed the job fail.
- [ ] `docs/NET-HOST-GATE-VERDICT.md` is merged in mycelium-cli with raw measurement output and one explicit, human-reviewed verdict sentence; a corresponding CI assertion exists whose pass/fail state matches that verdict.
- [ ] No caller in this package sets `depth` (or equivalent) past `check` for any `*-myc` repo, and no PLACEHOLDER build/test step in reusable-ci-mycelium.yml was modified — verifiable by diffing reusable-ci-mycelium.yml before/after this package (should be unchanged).

## Adversarial review checklist

- [ ] Do the caller blocks use the ACTUAL existing input names (`project-dir`, not `project-root`; verified against the live YAML) — no invented interface?
- [ ] Is `check` preserved as the sole job name at every caller (both reusable-ci-mycelium.yml and reusable-ci-rust.yml call sites) — a rename silently un-gates the whole train per both workflows' own header comments?
- [ ] Was any `*-myc` caller PR opened/merged BEFORE ap-workflows PR #30 merged and the image republished? (Sequencing violation — produces the misleading 'myc-check not found on this runner' failure instead of a real finding.)
- [ ] Does every migrated repo's `dev` branch protection get repointed to the new `<caller>/check` context in the SAME train as the caller PR — not left dangling on a context that will never report again (the fail-closed window this repo's own sync-required-contexts.sh documents)?
- [ ] Is `acknowledge-not-adopted: true` still required and un-defaulted in reusable-ci-mycelium.yml — was the workflow's own refusal-to-run-unacknowledged step left intact, not 'fixed away' to make onboarding quieter?
- [ ] Are mycelium-lang and mycelium-lang-myc excluded from the bulk migration, with their divergent lock-format/draw-in-matrix job model left untouched and explicitly flagged for separate human review?
- [ ] Does mycelium-bench's new gate actually invoke `cargo run --release --bin bench` (not merely `cargo bench --no-run` against nonexistent Criterion targets, which would be silently vacuous again)?
- [ ] Was the mycelium-bench 'non-vacuous' proof (empty-corpus commit that fails, then reverted) actually performed and is there evidence (a linked CI run) rather than an assertion?
- [ ] Is the net-host verdict document's sign-off attributed to someone other than the implementing agent, and does the shipped CI assertion's direction (must-not-appear vs. documented-and-failing) match the verdict rather than being pre-decided?
- [ ] Are any of the 94 generated caller PRs batched into a single mega-PR, violating the 'ONE PR per repo, never batched' convention this train already uses?
- [ ] Does any generated caller introduce `apt-get`/package-install steps into a non-image-build job, violating the rootless/no-new-privs runner constraint?
- [ ] Is `ecosystem-lock-ref` used (not raw git-rev edits to individual Cargo.toml files) for any cross-repo pin change touched by this package, per the no-path-deps / git-dep-pins constraint?

## Blocked by

- Human/orchestrator approval to merge tzervas/ap-workflows PR #30 (code is ready and CLEAN/MERGEABLE now; merging it is a decision this sub-planner cannot make).
- Orchestrator opening a hub issue for PKG-CI-TRUTH in tzervas/mycelium-lang and assigning it a package status per the schema — required by the kickoff rule before any implementer starts; not yet done as of this design.

## Risks

- Turning `deny-warnings: true` on for all 45 *-myc repos makes them red immediately and by design (13+ findings already measured in just one repo; only 4/8 scanned repos are clean) — this WILL read as a mass regression to anyone not briefed on the plan; needs a heads-up/communication step alongside the rollout, not a design change.
- Required-status-check renaming has a fail-closed window across up to 94 repos; sequencing branch-protection updates wrong (or too slowly) blocks unrelated PRs fleet-wide until the ruleset catches up. Mitigate by following the existing script's documented order (caller merges first, ruleset second) and batching, not big-banging, the rollout.
- mycelium-bench's real corpus, once actually run in CI, may surface genuine interp-vs-AOT capability/correctness LOSSes — that is a correct and expected outcome of closing this gap, not a defect in this package, but could be mistaken for 'this package broke bench.'
- The net-host leak's root cause is genuinely unknown from this package's evidence (manifest-level inspection shows no obvious misconfiguration); lane 5 may legitimately conclude only 'measured, verdict pending further engineering,' and success criteria must accept a documented-and-escalated outcome as valid rather than forcing a guessed code fix.
- Self-hosted fleet capacity: moving up to 94 repos' CI from GitHub-hosted `ubuntu-latest` onto the self-hosted rootless podman fleet simultaneously is a queueing/capacity risk if the fleet is small; roll out in waves, watch queue depth, not one mass PR wave.
- Scale mismatch with the 'one lane per repo' rule: this package genuinely touches ~94 component repos. Treating each as a hand-designed zipper lane would be an enormous planning tax for zero-design mechanical work; this design deliberately collapses them into two script-generated batches (lanes 2 and 3) governed by one frozen template each — flagging this explicitly since it is a deviation from strict one-decision-per-repo, done for the reason ap-workflows' own rollout-callers.sh already established as correct for exactly this shape of change.
- GPU/FAIL_ENV applicability to mycelium-bench specifically is unconfirmed — no backend in the repo currently requires a device (mlir-dialect gracefully Skips on toolchain absence, which is not the same as a GPU device check). Do not fabricate a GPU job for mycelium-bench in this package; leave it flagged unknown pending a human decision on whether any backend will ever need one.

## Provenance

Designed 2026-08-04 by sonnet sub-planners (workflow `wf_3b412561-c1d`) against **measured**
behaviour, not the narrative docs — which are known stale. See `docs/CAPABILITY-MATRIX.md` and
`probes/`. Per `AGENT-PIPELINE.md` the kickoff rule is absolute: no implementer starts without a
merged package, a linked surface freeze, a hub issue and machine-checkable criteria.
