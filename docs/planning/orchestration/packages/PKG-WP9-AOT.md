# PKG-WP9-AOT — AOT to a real user-facing native path (mandatory)

| Field | Value |
|---|---|
| **WP** | WP-9 |
| **Priority** | P0 |
| **Status** | pre-freeze |
| **Hub** | https://github.com/tzervas/mycelium-lang/issues/47 |
| **Effort** | L |
| **Requires re-pin** | yes |

## Goal

Make AOT a real user-facing native path — measured first, then wired. TODAY, measured with the built `myc` at /root/.claude/jobs/7153dd73/tmp/mycbuild/mycelium-cli/target/release/myc: `myc build --native` exits 64 (EX_USAGE — the flag does not exist; it falls through with_run_options' `_ => usage()` arm); `myc build` exits 0 but only ever calls mycelium_spore::build_spore (mycelium-cli has zero dependency on mycelium-codegen or mycelium-core; verified by grep of Cargo.toml/src/lib.rs); mycelium-codegen's mycelium-mlir crate has NO [[bin]] and its only public compiled-artifact API (`CompiledArtifact::run`) executes the binary once, reads back one stdout line as a typed Value, and then drops it — its backing `TmpDir` deletes the file on Drop, so there is literally no public way today to extract a compiled binary onto disk. This package (1) freezes and lands the measurement layer — a Rust-level capability corpus in mycelium-codegen (constructs lower vs refuse, at the codegen-API layer) plus 5 new .myc probes and an `@expect-build` header extension to mycelium-lang's existing capability-probe.sh harness (constructs lower vs refuse, at the myc-CLI layer, once it exists) — and (2) only then wires a real, additive `myc build --native --out <path>` that reuses the exact parse/check/elaborate pipeline `myc run` already trusts, feeds the resulting mycelium_core::Node to mycelium_mlir::llvm::compile(), and persists the result via a new CompiledArtifact::persist API. It does NOT touch `myc build`'s existing spore output, which stays the publication target (crates.io is permanently off; the spore registry is the real target) — `--native` is strictly additive. STATED PLAINLY: the recursion-inclusive rows (FixGroup / non-tail Fix via the trampoline) of both the capability corpus and the aot-recursive-fixgroup probe CANNOT be sized until tzervas/mycelium-codegen#19 (B1/B2, currently OPEN, MERGEABLE, CI green, targets `main`) merges — that PR is literally what changes their expected results. The non-recursive V0 slice (scalar Binary/Ternary ABI + non-recursive Construct/Match + unquantized Dense) does not depend on #19 and can be measured and wired in parallel.

## Non-goals

- Host-effect (`wild:`) codegen — epic ask #4 of codegen#5. Zero representation of HostCallRegistry/wild dispatch exists anywhere in llvm.rs or trampoline.rs (verified by grep — no 'wild'/'HostCall' token in either file). This needs its own ABI design (how a compiled native binary calls into the same host ops mycelium-std-sys-host installs for the interpreter — likely dynamic linking against a shared host library) and is explicitly out of scope for this package; it is a distinct follow-on.
- General closures / arbitrary Lam+App outside the narrow self/sibling-call trampoline shape (epic ask #2) — stays refused; not attempted here.
- General recursive/heap ADTs, strings, general user-defined types beyond the non-recursive stack-alloca Construct/Match fragment (epic ask #1) — stays refused; not attempted here.
- Repr::Vsa and quantized Dense (BitNet packings) — stays refused; not attempted here.
- A manifest-level ([native] table in mycelium-proj) or a default `--out` path — V0 requires `--out <path>` explicitly rather than inventing an unreviewed convention; mycelium-proj is not touched by this package.
- Merging mycelium-codegen#8 (classify_arm stray-self FixGroup shadowing guard) — LOW severity, no current test hits it; this package must not silently mark that pathological shape as safe, but fixing it is not required to ship V0.
- Retrofitting the compiled-artifact execution model (single-stdout-line read-back protocol with sentinel bytes) into general process semantics (argv/stdin/side effects) — V0 inherits and documents this contract as-is.

## Surfaces (frozen by L-ZIP before any implementer starts)

- [`S-AOT-NATIVE-COMPILE`](../surfaces/S-AOT-NATIVE-COMPILE.md) — tzervas/mycelium-codegen
- [`S-AOT-CAPABILITY-CORPUS`](../surfaces/S-AOT-CAPABILITY-CORPUS.md) — tzervas/mycelium-codegen
- [`S-AOT-BUILD-CLI`](../surfaces/S-AOT-BUILD-CLI.md) — tzervas/mycelium-cli
- [`S-AOT-PROBE-HARNESS`](../surfaces/S-AOT-PROBE-HARNESS.md) — tzervas/mycelium-lang

## Lanes

| Lane | Repo | Role | Done when |
|---|---|---|---|
| `L-ZIP` | tzervas/mycelium-lang | zipper | All surface files merged; no implementer lane starts before this. |
| `L-TZERVAS-MYCELIUM-COD` | tzervas/mycelium-codegen | implementer | `cargo test -p mycelium-mlir` is green including capability_corpus.rs with >=7 fixtures (one per enumerated 'beyond scalar ABI' category) each asserting a liter |
| `L-TZERVAS-MYCELIUM-CLI` | tzervas/mycelium-cli | implementer | `myc build --native --out <tmp>` on the `aot-scalar-in-subset` probe program exits 0 and the file at `<tmp>` is directly executable (run it as a subprocess, not |
| `L-TZERVAS-MYCELIUM-LAN` | tzervas/mycelium-lang | implementer | `MYC=/root/.claude/jobs/7153dd73/tmp/mycbuild/mycelium-cli/target/release/myc scripts/capability-probe.sh` run TODAY (before any implementation lane lands) repo |

## Success criteria

- [ ] Day-0 (measurement-only, checkable immediately with the existing prebuilt myc, no implementation required): capability-probe.sh with the @expect-build extension reports all 5 new AOT probes as-expected at build=64.
- [ ] cargo test -p mycelium-mlir in mycelium-codegen is green including capability_corpus.rs, with >=7 fixtures each asserting a literal AotError/Ok variant rather than a bare is_err/is_ok.
- [ ] CompiledArtifact::persist is public, documented, and its round-trip test (compile -> persist(tmp) -> execute the persisted file directly as a subprocess) passes and matches the value CompiledArtifact::run() reports for the same program.
- [ ] myc build --native --out <path> on the aot-scalar-in-subset probe program exits 0 and writes an independently-executable native binary at <path>.
- [ ] myc build --native --out <path> on aot-closure-capture and aot-wild-effect exits 70 (error[myc-build-native-unsupported]) naming the specific refused construct, never a raw panic and never a silent fallback to spore-only success.
- [ ] myc build (no --native) is byte-for-byte unchanged versus pre-package behavior on every existing spore fixture in mycelium-cli's test suite.
- [ ] docs/planning/orchestration/packages/PKG-WP9-AOT.json validates against schemas/work-package.schema.json.
- [ ] PR #19 (B1/B2) is merged to codegen's confirmed integration branch; only then is the aot-recursive-fixgroup probe's @expect-build value filled in (with the merge commit SHA cited in its @note) and only then does the capability corpus assert non-error results for the trampoline's linear FixGroup/non-tail-Fix shape.
- [ ] Neither the CLI lane nor the codegen lane introduces any wild/host-effect codegen, general-closure codegen, or heap-ADT codegen — verified by the corpus's refusal fixtures for those categories staying refused after all other lanes land.

## Adversarial review checklist

- [ ] Does the mycelium-codegen PR honor the frozen CompiledArtifact::persist signature exactly (no silent rename/reshape of the S-AOT-NATIVE-COMPILE contract)?
- [ ] Is `myc build` (no --native) proven byte-for-byte unchanged, not just 'looks the same' — is there an actual diff-based regression test against pre-change fixtures?
- [ ] Is every native-build refusal a distinct, actionable Report naming the exact construct/AotError variant — never a raw panic, never a silent fallback that reports spore-only success as if --native had succeeded?
- [ ] Does the exit-code table implemented match exactly what S-AOT-BUILD-CLI froze (69 toolchain-missing, 70 unsupported-construct) — no new ad hoc sysexit invented without a doc update?
- [ ] Is the persisted binary verified by running the FILE directly as a subprocess, not merely by calling the crate's own .run() again (which would hide an argv/permissions/relocation bug introduced by persist())?
- [ ] Does capability_corpus.rs assert the specific AotError variant per fixture (UnsupportedNode/UnsupportedRepr/etc.), not just Result::is_err()?
- [ ] Is the aot-recursive-fixgroup probe's @expect-build value backed by an actual PR #19 merge commit SHA cited in its @note, rather than asserted ahead of the merge?
- [ ] Does aot-wild-effect's @note correctly frame host-effect codegen as explicitly out-of-scope for this whole package (not phrased as 'coming soon'), so nobody later treats a future accidental pass here as intended progress?
- [ ] Is mycelium-mlir pulled into mycelium-cli strictly via git rev (ecosystem-lock-ref discipline), with zero path deps reintroduced across the three separate repos?
- [ ] Does the new mycelium-codegen test (capability_corpus.rs) skip gracefully (ToolchainMissing) on rootless CI runners lacking llc/clang, per the codebase's own established idiom — or does it hard-fail and break CI on runners without the toolchain?
- [ ] Does the capability-probe.sh change stay purely additive — do the pre-existing 15 probes still produce byte-identical CAPABILITY-MATRIX.md rows?
- [ ] Is there an explicit, uncommented note in the capability corpus linking codegen#8 (classify_arm stray-self FixGroup shadowing guard) rather than silently treating that pathological shape as verified-safe?

## Blocked by

- tzervas/mycelium-lang PR #41 (feat/capability-matrix, open, base main) — must merge (or this package's lane must explicitly rebase onto it) before the S-AOT-PROBE-HARNESS work lands, since both touch scripts/capability-probe.sh and probes/.
- tzervas/mycelium-codegen PR #19 (B1/B2 promotion, open, mergeable, CI green, currently targets main) — required only for the recursion-inclusive success criteria (aot-recursive-fixgroup probe, FixGroup/non-tail-Fix capability-corpus rows). The scalar-ABI + non-recursive-data + Dense-unquantized V0 slice does not depend on it and can proceed in parallel; this is stated explicitly because the sizing of the recursion rows cannot be done until the merge lands and its actual diff is known.

## Risks

- The core cross-repo assumption — that mycelium_l1::elaborate()'s mycelium_core::Node is accepted as-is by mycelium_mlir::llvm::compile() — is inferred from matching Cargo.toml pins (both currently @ 57ef45b453eef1f02bdfb1f0cad1034dabd32b1f) observed in this session, NOT verified by an actual build. It must be re-checked at lane kickoff, not trusted from this snapshot.
- Pin drift: mycelium-cli, mycelium-l1, and mycelium-codegen are three independently git-dep-pinned repos with lockfiles deliberately untracked across the train; nothing currently keeps their mycelium-core pins in lockstep except manual re-pin PRs (the S-ECOSYSTEM-LOCK discipline). A drift between when this package is designed and when it is implemented could silently break the S-AOT-BUILD-CLI spike.
- The proposed exit-code table (69 for toolchain-missing, 70 reused for construct-refusal under a new error string) is this package's proposal, not a ratified RFC/ADR — the codebase clearly runs an RFC-/ADR-numbered process elsewhere and this choice should get an explicit review pass, not ship as a fait accompli.
- Scope creep risk is high and specific: because `wild` just became measured-CLOSED (mycelium-lang#16 functionally closed), an implementer may be tempted to also attempt host-effect codegen while wiring the CLI. This is explicitly a non-goal — it needs its own ABI design (how compiled native code calls into HostCallRegistry) and is sized as unknown/out-of-scope here.
- codegen#8 (classify_arm stray-self FixGroup shadowing guard) stays open; LOW severity per its own filing (no current program triggers it), but the capability corpus must carry an explicit known-gap fixture rather than silently certifying that shape as safe.
- CompiledArtifact::persist's correctness on non-Linux/non-glibc targets is unverified in this session — the compile pipeline shells to llc+clang and persist() is a simple file copy, so risk is believed low, but no cross-platform test exists yet.
- PR #19 currently targets `main`, but the train's DECIDED convention is that `dev` is now the integration branch and `main` carries no required checks — if this mismatch isn't resolved before merge, the B1/B2 gates could land somewhere that doesn't actually gate the train, silently reproducing the exact 'stranded on dev' problem PR #19 was written to fix.

## Provenance

Designed 2026-08-04 by sonnet sub-planners (workflow `wf_3b412561-c1d`) against **measured**
behaviour, not the narrative docs — which are known stale. See `docs/CAPABILITY-MATRIX.md` and
`probes/`. Per `AGENT-PIPELINE.md` the kickoff rule is absolute: no implementer starts without a
merged package, a linked surface freeze, a hub issue and machine-checkable criteria.
