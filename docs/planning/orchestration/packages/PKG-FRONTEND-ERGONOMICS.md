# PKG-FRONTEND-ERGONOMICS — Frontend surface: statement sequencing, method/postfix, () unit spelling

| Field | Value |
|---|---|
| **WP** | WP-12 |
| **Priority** | P1 |
| **Status** | pre-freeze |
| **Hub** | https://github.com/tzervas/mycelium-lang/issues/46 |
| **Effort** | L |
| **Requires re-pin** | no |

## Goal

Close the three frontend ergonomics gaps that block 'ordinary programs' in Mycelium L1 — statement sequencing, method/postfix call syntax, and the `()` unit spelling — as measured by mycelium-transpile --vet on real Rust (multi-statement 38+, method sugar 31+, unit 13+ per hub issue tzervas/mycelium-l1#6). All three are parser-only (KC-3, zero kernel/eval/mono growth), matching the codebase's own precedent (the already-landed-but-unmerged block-sequencing PR). Landing them removes the specific frontend blocker that stops an IR modelling imperative statement sequences or method dispatch from lowering to .myc (py2rust -> IR -> Rust, mycelium-transpile consuming the same IR).

## Non-goals

- Non-unsigned/string/struct value-type gaps (14+ in the vet count) — tracked by hub issue l1#6 but explicitly excluded from this package's repo/LOC scope; a separate package.
- Named-field record syntax / `.field` projection (G4, DN-106 fork B was REJECTED) — this package's dot-postfix production is call-only (`.ident(args)`), never a bare field-access form.
- Fixing the CLI's `myc run` refusal of `CoreValue::Data` results (open gap #2 in the ground truth) — pre-existing, mycelium-cli-owned, unrelated to parsing; success criteria route around it by using scalar-returning fixtures where run-verification is claimed.
- A losslessly-round-trippable AST node for method calls in mycelium-l1 (would let mycelium-fmt/mycelium-transpile recover original `.method()` vs `method(x)` surface shape after parse). This package deliberately desugars at parse time with NO new AST node (same shape as the landed block-sequencing precedent), which is irreversibly lossy for fmt round-trip — accepted as a documented limitation, not fixed here.
- Full production-grade closure of the mycelium-transpile vet counts to zero. This package delivers one representative, tested emission path each for the MultiStmtBody-via-semicolon-statement case and the unmapped-method-call case, plus a fresh honest before/after --vet count. Driving every one of the 38+/31+ real sites to green is follow-on scope.
- Cross-nodule/cross-crate import mechanism work (OPEN gap #1, the 26 unreachable mycelium-std-* crates) — orthogonal keystone gap, not in this package's repo set.
- wild-boundary type enforcement, AOT native path, --version, or any of the other OPEN ground-truth gaps not named in this package's WHAT-THIS-COVERS list.

## Surfaces (frozen by L-ZIP before any implementer starts)

- [`FE-1-BLOCK-SEQ`](../surfaces/FE-1-BLOCK-SEQ.md) — mycelium-l1
- [`FE-2-UNIT-PAREN`](../surfaces/FE-2-UNIT-PAREN.md) — mycelium-l1
- [`FE-3-METHOD-POSTFIX`](../surfaces/FE-3-METHOD-POSTFIX.md) — mycelium-l1

## Lanes

| Lane | Repo | Role | Done when |
|---|---|---|---|
| `L-ZIP` | tzervas/mycelium-lang | zipper | All surface files merged; no implementer lane starts before this. |
| `L-MYCELIUM-L1` | tzervas/mycelium-l1 | implementer | `gh pr list --repo tzervas/mycelium-l1 --state merged` shows #7, #8, #9, plus the new unit-paren-sugar and method-postfix-call PRs, all merged to `dev` with the |
| `L-MYCELIUM-TRANSPILE` | tzervas/mycelium-transpile | implementer | A `train/repin-l1-<sha>` PR is merged bumping the `mycelium-l1` git-rev pin in `Cargo.toml`. `cargo test` (full suite) passes with 0 regressions. New tests in ` |
| `L-MYCELIUM-FMT` | tzervas/mycelium-fmt | implementer | A `train/repin-l1-<sha>` PR is merged. `cargo test` passes with 0 regressions. A new golden fixture proves `let _ = a in let _ = b in c` (and 3+ deep chains) re |

## Success criteria

- [ ] `fn f() => Binary{8} = { g(0b0000_0001); g(0b0000_0010); 0b0000_0011 };` parses, `myc check` exits 0, and this is proven by a merged PR to mycelium-l1 `dev` (PRs #7, #8, #9 rebased+merged), not a fresh reimplementation.
- [ ] `fn f() => Unit = ();` and a `()` return-type spelling both parse and `myc check` exits 0; both produce parse-AST identical to hand-writing `Unit` (word form), verified by an explicit AST-equality test.
- [ ] `fn f() => Binary{8} = answer().identity();` (the exact roadmap repro, reproduced failing today at parse position 4:31 'found Dot') parses, `myc check` exits 0, and `myc run` returns the correct scalar value.
- [ ] `d.g` (a bare non-call dotted identifier chain) still parses to a 2-segment Path and still fails `myc check` with the SAME 'multi-segment qualified-path ... deferred in v0 (M-662)' message it produces today — zero regression in the existing (dead but explicitly-refused) qualified-path route.
- [ ] `use foo.bar;`, a `nodule x.y;` header, and a `Ctor(sub)` pattern all still parse byte-identically before and after the FE-3 change (regression tests included in the PR).
- [ ] mycelium-transpile: at least one previously-`Category::MultiStmtBody`-gapped Rust fn body (semicolon-terminated statement before the tail) now emits valid `.myc` instead of gapping, proven by a before/after test in `src/tests/emit.rs`.
- [ ] mycelium-transpile: at least one previously-gapped unmapped Rust `.method()` call now emits Mycelium dot-syntax instead of gapping, proven by a before/after test.
- [ ] mycelium-transpile: a fresh `--vet` run against the reference corpus (gha-runner-ctl, per l1#6) records MultiStmtBody and method-call gap counts strictly below the roadmap's cited 38+/31+ baseline, with exact numbers in the PR.
- [ ] mycelium-fmt: a `let _ = a in let _ = b in c` fixture reformats to `{ a; b; c }`, and a pinned fixture documents that method-call round-trip is NOT attempted (by design, per FE-3).
- [ ] All PRs across all three repos target `dev` (never `main`), cite hub issue tzervas/mycelium-l1#6, and no repo gains a committed Cargo.lock.
- [ ] Full `cargo test --release` in each of the three repos passes with zero regressions relative to each repo's current `dev` tip.

## Adversarial review checklist

- [ ] Diff mycelium-l1's FE-2/FE-3 PRs and confirm ZERO lines touch eval.rs, checkty.rs (beyond, at most, an unavoidable error-message string), mono.rs, or elab.rs — everything must be parse.rs + tests + grammar doc (KC-3 zero-kernel-growth claim must hold, not just be asserted).
- [ ] Independently re-derive the FE-3 disambiguation-safety argument (that multi-segment Path is unconditionally check-refused today) by running `myc check` against a fresh `d.g` fixture on the PRE-change tree — do not trust this document's citation alone.
- [ ] Run the FULL existing conformance/accept/reject corpus (`tests/conformance.rs` and friends) before and after FE-3 lands, diffed byte-for-byte, to catch any accidental behavior change in unrelated dotted-path use sites (`use`, `nodule`, `phylum`, `swap policy:`, pattern `Ctor(sub)`).
- [ ] Confirm the mixed-chain edge case `a.b.c(x)` (non-call intermediate segment before a trailing call) is covered by an explicit test and produces the documented check-time refusal on `a.b`, not a parse error and not a silent misinterpretation as `c(a.b, x)`.
- [ ] Confirm PR #8's two hard block-refusals (empty `{}`, trailing `;`) were EXPLICITLY revisited once FE-2 landed — either intentionally left refusing (with an updated, non-stale error message) or intentionally upgraded to desugar to `Unit` — and that whichever was chosen has its own test, not just a deleted assertion.
- [ ] Confirm mycelium-transpile's new method-call emission path still gaps (never fabricates) any call where receiver/method resolution is ambiguous or unknown — spot-check against `is_unmappable_conversion_method`/`ReceiverGate::AnyBuiltinScalar` cases to ensure those correct existing refusals were not accidentally loosened.
- [ ] Confirm mycelium-transpile's semicolon-statement lowering threads `local_env` type tracking identically to the existing `let`-chain path (no silent loss of type info for bindings/expressions after the first non-let statement).
- [ ] Confirm mycelium-fmt's block-canonicalization is round-trip safe: `parse(fmt(parse(src))) == parse(src)` on a representative corpus, not just visually plausible output.
- [ ] Confirm every cross-repo PR (mycelium-transpile, mycelium-fmt) references the exact mycelium-l1 commit SHA it was repinned to, and that the repin PR itself is a separate, reviewable `train/repin-l1-<sha>`-style commit (per this ecosystem's existing convention) — not silently folded into a feature PR.
- [ ] Confirm no PR targets `main` and no repo gained a tracked Cargo.lock.
- [ ] Confirm the `--vet` before/after numbers quoted in the mycelium-transpile PR were actually run on the stated corpus in this session (or are clearly marked as a claim to be verified), not carried over from the roadmap's original (now possibly stale) figures.

## Risks

- MEDIUM: the FE-3 parse_path/parse_app disambiguation design is this document's own novel derivation — it is NOT something the existing mycelium-l1 test suite or maintainer commentary has already validated (unlike FE-1, which is copied from an already-tested branch). It is grounded in a verified fact (check_path's unconditional multi-segment-path refusal) but the adversarial reviewer must independently re-derive it before implementation proceeds, per the review checklist.
- LOW (verified, not assumed): rebase conflict risk for PRs #7/#8/#9 onto current `dev` tip. Checked directly — the only intervening commit (5c031df) touches only `.github/workflows/fleet-ci.yml`, `fleet-security.yml`, `docs/FLEET_STANDARDS.md`; zero overlap with `parse.rs` or the new test files.
- MEDIUM: mycelium-transpile and mycelium-fmt lanes are hard-blocked on an l1-repin PR (git-dep pin bump, no path deps in this ecosystem) landing AFTER the l1 PRs merge — a real sequential dependency, not parallelizable with the l1 lane despite being 'separate repos'; scheduling must respect it or the two downstream lanes will simply fail to compile against old syntax.
- MEDIUM: full closure of the transpile vet counts (38+/31+) to zero is explicitly NOT promised by this package — only a representative working path plus an honest before/after delta. If stakeholders expect the roadmap's raw counts to hit zero, that expectation must be corrected before kickoff, not discovered at review.
- LOW-MEDIUM: mycelium-fmt's inability to round-trip method-call surface (no new AST node in FE-3) is a deliberate, accepted, but real forward-compatibility cost. If a later package needs lossless formatting fidelity for method calls, FE-3 will need to be revisited (promote to a real AST node), which is a larger, riskier change than what's frozen here — flagged now so it isn't rediscovered as a surprise.
- UNVERIFIED / needs human: whether the hub issue's stated 'Autoclosure: Closed by the delivering PRs to main' text (which predates the dev-is-integration-branch decision) should be updated to say `dev`, or whether issue #6 should only auto-close once the non-unsigned/string/struct-type gap (out of this package's scope) also lands — recommend the human orchestrator decide the issue's closure condition explicitly rather than letting a `Closes #6` in a `dev`-targeted PR silently close an issue that's only 3/4 addressed.

## Provenance

Designed 2026-08-04 by sonnet sub-planners (workflow `wf_3b412561-c1d`) against **measured**
behaviour, not the narrative docs — which are known stale. See `docs/CAPABILITY-MATRIX.md` and
`probes/`. Per `AGENT-PIPELINE.md` the kickoff rule is absolute: no implementer starts without a
merged package, a linked surface freeze, a hub issue and machine-checkable criteria.
