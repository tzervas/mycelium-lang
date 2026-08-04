# Adversarial review: structured input + strict rubric

`AGENT-PIPELINE.md` defines an **adversarial review agent** stage between the implementer lanes and
the merge gate. This documents *how* to run it against an external model so that it works, because
the obvious approach does not.

## The finding

Prose briefs that ask a model to "attack this PR" fail. Measured over **five reviews, zero usable
results**:

- one run flip-flopped through four self-revised drafts (KICKBACK → narrowed → APPROVE) and exited 1
- two were cancelled on turn budget mid-analysis, emitting no verdict
- one spent most of its budget exploring unrelated local checkouts that did not contain the PR
- several findings were confidently false: hedging *"if it differs, verify"* instead of checking, and
  flagging a file that was not in the diff at all

Re-running **the same model and the same harness** with structured input and a numbered rubric:

| | prose "attack this PR" | structured input + rubric |
|---|---|---|
| valid output | 0 of 5 | yes |
| turns | 8, then cancelled | **1** |
| wall clock | budget exhausted | ~130 s |
| cost | wasted | ~$0.06 |

It also caught a real error the author had missed — a claim attributed to a frozen surface when the
supporting language actually lived in a module rustdoc, two documents conflated.

The lesson is not "the model is good" or "the model is bad". It is that **an unbounded critique task
has no completion condition**, so the model wanders or oscillates. A rubric supplies one.

## The five properties that matter

1. **Structured input as JSON** — `review_target`, `context` (including the author's explicit
   claims), and a `rubric` array of `{id, question, evidence_required}`.
2. **Everything inline, exploration forbidden.** Paste the diff and every spec the rubric needs, then
   say plainly: *do not explore the filesystem, clone anything, or read other repositories*.
   Wandering is what exhausted the budget in every failing run.
3. **Three-valued verdicts: `PASS` / `FAIL` / `CANNOT_DETERMINE`.** The third value is what removes
   hedging. Without it the model answers "you should verify X", which is not a review. With it, the
   model must either decide or name the exact missing input — and naming the missing input is itself
   useful signal.
4. **Every `FAIL` must quote a provided line.** State that *an unquoted FAIL is invalid*. This alone
   eliminated the false findings.
5. **Say that a well-evidenced PASS beats a speculative FAIL.** Otherwise the model invents findings
   to look rigorous, which costs more to refute than it saves.

## It adjudicates well and hunts poorly

Do not ask it to discover unknown unknowns. Give it **candidate defects to rule on** — a rubric item
of the form *"consider specifically: A, B, C"* — and it reasons about each accurately, including
correctly rejecting non-defects. Its own unprompted findings have a poor hit rate.

## Two operational cautions

- The external model is **not bound by the rules given to workflow subagents**. Left unconstrained it
  read other sessions' working copies. Always pin its working directory to a throwaway clone.
- Its structured-output mode is unreliable for long open analysis but fine for bounded work. Keep the
  rubric to roughly a dozen items; split larger reviews rather than growing one brief.

## Usage

```sh
scripts/adversarial-review.sh \
  --repo tzervas/mycelium-runtime --pr 19 \
  --rubric docs/planning/orchestration/rubrics/lane-pr.json \
  --spec docs/planning/orchestration/surfaces/S-PRIMSIG-SCHEMA.md \
  --out /tmp/rev-19
# -> /tmp/rev-19/review.json
```

`rubrics/lane-pr.json` is the default rubric for an implementer-lane PR: claim fidelity, tautological
tests, real-vs-cosmetic change, never-silent violations, frozen-surface drift, scope creep,
overclaimed criteria, and adjudication of supplied candidates. Repeat `--spec` for each frozen
surface or package file the rubric must be answerable against.

## The verdict is advice, not a gate

A human or sonnet reviewer should still verify the strongest `FAIL` independently. The model has been
wrong before, and an unverified reviewer is a second opinion with extra steps. What the rubric buys is
a hit rate high enough to be worth reading — not authority.
