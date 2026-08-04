# PKG-INTERP-CORRECTNESS — Interpreter/CLI correctness: data results, let+wild residual, --version

| Field | Value |
|---|---|
| **WP** | WP-11 |
| **Priority** | P0 |
| **Status** | pre-freeze |
| **Hub** | https://github.com/tzervas/mycelium-lang/issues/45 |
| **Effort** | M |
| **Requires re-pin** | no |

## Goal

Close 3 measured interpreter/CLI correctness defects plus the --version gap that blocks ap-workflows' version pin, each as a small, single-repo, test-pinned fix against MEASURED behavior (not the stale docs): (a) `myc run` refuses any program whose `main` evaluates to an algebraic data/ADT value (calls Interpreter::eval, which hard-refuses CoreValue::Data) instead of calling the already-existing Interpreter::eval_core and rendering the result; (b) mycelium-l1's elaborator silently drops a `let`'s own type ascription and re-infers in synthesis mode, which fails specifically for a `wild { ... }`-bound let (wild has no synthesizable type by design) even though the identical program checked clean under `myc check` — EX_SOFTWARE 70 at run time on a program `myc check` already called healthy; (c) the wild-boundary result type is trusted, never verified against what the host op actually returns, and today this failure mode is completely SILENT (checks clean, runs clean, wrong value flows into ordinary code) which violates this project's own G2 "never silent" posture even though full static/dynamic enforcement is out of reach for a single-repo package; (d) `myc --version` and `myc-check --version` both fail today (exit 64 / exit 66) which blocks ap-workflows/reusable-ci-mycelium.yml's `mycelium-version` pin-verification step from ever succeeding.

## Non-goals

- Adding an import/module mechanism (gap 1) — separate keystone package, not touched here
- Building a native/AOT code path (gap 7) — separate package, AOT is mandatory per the DECIDED list but out of scope for this interpreter/CLI package
- Adding method/postfix dot syntax (gap 6) or multi-statement `;`-sequencing (gap 5) — separate ergonomics package; this package only adds a regression test that a nested let-chain containing `wild` at multiple depths still elaborates, it does not touch grammar
- Fixing the 45/95 placeholder-CI repos or mycelium-bench's no-op benchmarks (gap 9) — only the two specific --version calls this package needs are in scope
- Implementing REAL static or dynamic verification of wild-boundary result types against a registered host-op signature catalog. That requires a machine-checkable signature surface (today docs/planning/orchestration/surfaces/S-HOST-REGISTRY.md's 'Name catalog' is a PROSE markdown table, not code) that is PKG-LINKAGE's to freeze. This package only closes the SILENT half of the gap (a loud, unmissable disclosure) and hands PKG-LINKAGE a concrete, tested insertion point for the real check later.
- Human-readable constructor-name rendering for CoreValue::Data results. mycelium-core's own data.rs states plainly that a resolved DataDecl/CtorDecl carries NO name ('Names are stored separately (they are not identity — ADR-003)'), and mycelium-l1's own reveal.rs::render_surface already documents that no surface spelling survives elaboration to invert a Construct's ctor back to a name. This package ships the honest, always-correct, content-addressed `#<hash>#<i>(field, ...)` rendering (CtorRef's own Display) and explicitly flags human-name resolution as a distinct, larger follow-up (it would require threading a name index built from the pre-monomorphization Env through elaborate()'s internal monomorphize() call, which is not exposed today — see risks).
- Unifying myc's and myc-check's version *numbering scheme* across their two separate repos. Each binary reports its own `env!("CARGO_PKG_VERSION")` (`[workspace.package].version` in that repo's own Cargo.toml). At measurement time (2026-08-03) both happened to read "0.464.0", apparently kept in sync by existing fleet 'advance sibling pins to train version' automation observed in both repos' git logs — this package verifies that convention is sufficient for ap-workflows' substring-match consumer, it does not build new cross-repo version-sync machinery.
- Touching mycelium-runtime. Investigation (crates/mycelium-interp/src/lib.rs:695-724) confirms `Interpreter::eval_core` and `CoreValue` already exist, are already public, and need zero changes for gaps (a)-(c) as scoped. No mycelium-runtime lane is included.

## Surfaces (frozen by L-ZIP before any implementer starts)

- [`S-RUN-COREVALUE`](../surfaces/S-RUN-COREVALUE.md) — tzervas/mycelium-cli
- [`S-LET-REINFER`](../surfaces/S-LET-REINFER.md) — tzervas/mycelium-l1
- [`S-WILD-DISCLOSURE-DOC`](../surfaces/S-WILD-DISCLOSURE-DOC.md) — tzervas/mycelium-l1
- [`S-WILD-DISCLOSURE-CLI`](../surfaces/S-WILD-DISCLOSURE-CLI.md) — tzervas/mycelium-cli
- [`S-CLI-VERSION-MYC`](../surfaces/S-CLI-VERSION-MYC.md) — tzervas/mycelium-cli
- [`S-CLI-VERSION-MYCCHECK`](../surfaces/S-CLI-VERSION-MYCCHECK.md) — tzervas/mycelium-check

## Lanes

| Lane | Repo | Role | Done when |
|---|---|---|---|
| `L-ZIP` | tzervas/mycelium-lang | zipper | All surface files merged; no implementer lane starts before this. |
| `L-TZERVAS-MYCELIUM-L1` | tzervas/mycelium-l1 | implementer | `myc check` then `myc run` (against a locally re-pinned mycelium-cli, or a standalone `elaborate()` unit/integration test in mycelium-l1 itself) on `nodule proj |
| `L-TZERVAS-MYCELIUM-CLI` | tzervas/mycelium-cli | implementer | `myc run` on `fn main() => Unit = Unit;` exits 0 and prints a rendered CoreValue (today: rc=65, `error[myc-run-eval]: the program evaluated to a data value; use |
| `L-TZERVAS-MYCELIUM-CHE` | tzervas/mycelium-check | implementer | `out=$(myc-check --version 2>&1); rc=$?` gives rc=0 and `out` contains the exact `[workspace.package].version` string from this repo's Cargo.toml (measured toda |

## Success criteria

- [ ] `myc run` on `nodule proj; fn main() => Unit = Unit;` exits 0 (measured baseline today: rc=65, `error[myc-run-eval]: the program evaluated to a data value; use eval_core for the data fragment`).
- [ ] `myc check` then `myc run` on `nodule proj @std-sys; fn main() => Binary{64} !{ffi} = let discard: Binary{64} = wild { time_mono_nanos() } in discard;` both exit 0 (measured baseline today: check rc=0, run rc=70 `error[myc-run-residual]: ... could not re-infer `let discard`'s type: ... a `wild` block has no synthesizable type ...`).
- [ ] The same program shape with the let's declared type varied to at least one other repr (e.g. `Binary{8}`, or a `Seq`) also elaborates and runs successfully end-to-end — pins that the fix is not width- or repr-specific.
- [ ] The documented workaround `let discard = (wild { time_mono_nanos() }) : Binary{64} in discard` still checks and runs successfully, unchanged (regression guard on check_ascribe's independent path).
- [ ] `myc run` on `nodule proj @std-sys; fn main() => Unit !{ffi} = (wild { time_mono_nanos() }) : Unit;` still exits 0 (this remains a legitimately well-typed v0 program) AND its stderr now contains the wild-boundary disclosure banner text; the same command against a wild-free program (e.g. `fn main() => Unit = Unit;`) produces NO such banner line in stderr (measured baseline today: silent in both cases — zero disclosure either way).
- [ ] `out=$(myc --version 2>&1); rc=$?` gives rc=0 and `out` equals `mycelium-cli <version>` matching `[workspace.package].version` in mycelium-cli's Cargo.toml (measured baseline today: rc=64, full usage block printed instead).
- [ ] `out=$(myc-check --version 2>&1); rc=$?` gives rc=0 and `out` contains, as a literal substring, `[workspace.package].version` from mycelium-check's Cargo.toml (measured baseline today: rc=66, `io-error: --version: No such file or directory (os error 2)`); the exact shell logic in ap-workflows/.github/workflows/reusable-ci-mycelium.yml lines 134-155 passes its version-pin check against the fixed binary.
- [ ] Interpreter::eval() in mycelium-runtime is unmodified and its existing unit test (crates/mycelium-interp/src/lib.rs:1123, `assert_eq!(err, EvalError::DataResult)`) still passes unchanged — confirms gap (a)'s fix is CLI-side only, not a library-contract change.
- [ ] Every pre-existing green test in all three touched repos' own CI (mycelium-l1's differential/elaboration suite, mycelium-cli's tests/ directory, mycelium-check's oracle/project-mode tests) stays green after these changes — no regression.

## Adversarial review checklist

- [ ] Confirm `Interpreter::eval()` in mycelium-runtime is untouched and still refuses CoreValue::Data with EvalError::DataResult unchanged — the fix must be scoped to the CLI's own call site (eval -> eval_core), never a change to eval()'s documented library contract.
- [ ] Confirm the `Expr::Let` fix only takes the new ascription-aware path when the surface `ty` is `Some(_)`; confirm the `None` fallback still calls the original, unmodified `infer_type` byte-for-byte — a reviewer should diff-test that every currently-passing unannotated-`let` program in the existing test corpus is unaffected.
- [ ] Confirm the new `infer_type_against`'s `Cx` construction mirrors `infer_type`'s field-for-field (`std_sys: true`, `ambient_policy: None`, `affine: Tracker::inert()`, `strictness: Strict`, etc. — checkty.rs ~10387-10446) — any divergence risks silently changing re-inference semantics for constructs other than `wild` that this package's tests don't happen to cover.
- [ ] Confirm the documented ascription workaround `(wild {...}) : T` still checks and elaborates identically post-fix (regression guard — check_ascribe's independent `resolve_ty`+`expected` derivation, checkty.rs:6891-6898, must remain untouched).
- [ ] Confirm `contains_wild(&Node)` is a truly EXHAUSTIVE match over every Node variant (Const/Var/Let/Op/Swap/Construct/Match/Lam/App/Fix/FixGroup) with no `_ => false` catch-all that could silently miss a `wild:` op nested inside, e.g., a Match alternative or a FixGroup member — construct a test program where the only `wild` call is inside a `helper()` function called transitively from `main` (not textually inside `main`'s own top-level body) and confirm the banner still fires.
- [ ] Confirm the wild-boundary banner does NOT fire for a program with zero `wild` blocks (no stderr noise regression for the common case) beyond the pre-existing, unconditional `cert_mode_line`.
- [ ] Confirm the wild-boundary banner's wording does not overclaim — it must say what is NOT verified, never imply verification now happens (G2/VR-5 — a reassuring-sounding but false message would itself be a silent-wrong-type risk in disguise).
- [ ] Confirm `render_datum`'s recursive walk over nested `Datum`/`CoreValue` cannot host-stack-overflow on a deeply-nested constructed value — mycelium-core's own datum.rs docstring flags that Clone/PartialEq/Drop on Datum/CoreValue are deliberately manual-iterative for exactly this reason (RFC-0041 §4.5/W3); a naive recursive `Display`-style renderer would reintroduce the same class of bug the kernel code was hardened against. Test at meaningful nesting depth (100+), expect graceful output or an explicit bounded refusal, never a crash.
- [ ] Confirm `--version` handling in both `myc.rs` and `myc-check.rs` runs BEFORE any manifest/project-directory resolution, so it works from an arbitrary cwd with no `mycelium-proj.toml` present.
- [ ] Confirm `--version` output is a single line to STDOUT only (not also/instead stderr) — ap-workflows' consumer captures stdout via `$(myc-check --version 2>/dev/null || true)` and does a plain substring match; a stderr-only or multi-line emission would silently break that check without any visible failure in this package's own tests unless the reviewer specifically re-runs the ap-workflows shell logic against the built binary.
- [ ] Confirm the mycelium-cli lane's `mycelium-l1` git-rev pin (Cargo.toml `rev = "..."`) is actually advanced to the merged mycelium-l1 lane commit before mycelium-cli's own gap-(b) checkable_done is claimed satisfied — these are two separate repos with no path deps, so landing the mycelium-l1 fix alone does not change `myc run`'s behavior until the pin moves.
- [ ] Confirm no lane silently reached into mycelium-runtime — this package's design explicitly found zero required changes there; any diff touching mycelium-runtime should be treated as scope creep and questioned.

## Risks

- The Expr::Let fix touches a dense, heavily-cross-referenced 11k+-line checker/elaborator pair (checkty.rs/elab.rs, full of DN-xxx/RFC-xxxx/M-xxx tagged invariants) — a shallow patch risks missing a subtlety the surrounding comments encode. Mitigate by copying `infer_type`'s Cx construction verbatim rather than hand-rewriting it.
- No existing `contains_wild`-style AST/Node walker was found anywhere in the codebase during research — the implementer must write this from scratch against Node's 11-variant grammar and get it genuinely exhaustive; an incomplete walk would make the new disclosure banner itself silently incomplete, which is precisely the failure mode this package exists to eliminate.
- The task framing raises 'check registered signatures (ties to PKG-LINKAGE)' as an option for gap (c); investigation shows that catalog is currently a prose markdown table (S-HOST-REGISTRY.md's 'Name catalog'), not machine-checkable data — if a reviewer expects this package to deliver real enforcement rather than disclosure, that expectation must be corrected before kickoff, not discovered mid-review.
- `myc --version`/`myc-check --version` values come from each repo's own `[workspace.package].version` (both read 0.464.0 at measurement time, 2026-08-03/04), apparently held in sync by existing fleet 'advance sibling pins to train version' automation observed in both repos' git logs (e.g. mycelium-cli PR #19). This package does not create or enforce that sync — if the fleet automation lapses, the two --version outputs could silently diverge again with no guard from this package.
- mycelium-cli pins mycelium-l1 via a git `rev =` (no path dep, no shared workspace) — the mycelium-l1 lane's fix has zero observable effect on `myc run` until mycelium-cli's Cargo.toml pin is advanced to the new commit and re-verified. This is a hard internal lane-ordering dependency even though the package-level `blocked_by` is empty (nothing outside this package blocks it).
- Rendering CoreValue::Data with real, human-readable constructor names (as opposed to this package's honest content-addressed `#<hash>#<i>(...)` fallback) would need a name index built from the pre-monomorphization `Env` (which DOES carry names, via `Env.types: BTreeMap<String, DataInfo>`) reconciled against the registry `elaborate()` builds internally from its OWN `monomorphize()`-transformed env (mono.rs) — these are not the same `Env`, and getting this wrong would silently mislabel a value, which is strictly worse than today's honest hash-based rendering. Deliberately left as a flagged follow-up, not attempted here.
- Given this project's own culture explicitly distinguishes measured from aspirational (the reason the docs rotted in the first place), success criteria intentionally point at exact reproduction commands measured live against the built `myc`/`myc-check` binaries during this planning pass rather than at the (possibly stale) doc comments in the source — an implementer should re-measure against their own checkout before trusting the exact line numbers cited above, since they will drift as soon as any of these lanes lands.

## Provenance

Designed 2026-08-04 by sonnet sub-planners (workflow `wf_3b412561-c1d`) against **measured**
behaviour, not the narrative docs — which are known stale. See `docs/CAPABILITY-MATRIX.md` and
`probes/`. Per `AGENT-PIPELINE.md` the kickoff rule is absolute: no implementer starts without a
merged package, a linked surface freeze, a hub issue and machine-checkable criteria.
