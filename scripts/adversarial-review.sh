#!/usr/bin/env bash
# Adversarial review of a PR, via an external model, using STRUCTURED INPUT + a STRICT RUBRIC.
#
# WHY THE STRUCTURE IS THE WHOLE POINT
# The AGENT-PIPELINE "adversarial review agent" stage was first attempted with prose briefs that
# said, in effect, "attack this PR". Measured over 5 reviews that produced ZERO usable results:
# one run flip-flopped through four self-revised drafts (KICKBACK -> narrowed -> APPROVE) and exited
# 1; two were cancelled on turn budget mid-analysis; one spent its budget exploring unrelated local
# checkouts; several findings were confidently false — hedging "if it differs, verify" instead of
# checking, and flagging a file that was not in the diff.
#
# Re-running the SAME model and harness with structured input and a numbered rubric:
#   EXIT=0, 1 turn (vs 8-and-cancelled), ~130s, ~$0.06, valid schema output.
# And it caught a real error the author had missed — a claim attributed to a frozen surface when the
# supporting text actually lived in a module rustdoc.
#
# The five properties that made the difference, all enforced below:
#   1. Structured input (JSON): review_target, context incl. explicit author_claims, and a rubric
#      array of {id, question, evidence_required}.
#   2. Everything inline (diff + spec text), and exploration FORBIDDEN. Wandering is what exhausted
#      the budget every time it failed.
#   3. Three-valued verdicts: PASS / FAIL / CANNOT_DETERMINE. The third value is what removes
#      hedging — the reviewer must decide or name the exact missing input.
#   4. Every FAIL must quote a provided line. "An unquoted FAIL is invalid."
#   5. A well-evidenced PASS is stated to be more useful than a speculative FAIL, so it stops
#      inventing findings to look rigorous.
#
# It ADJUDICATES well and HUNTS poorly: give it candidate defects to rule on rather than asking it to
# discover unknown unknowns. Put those in a rubric item as "consider specifically: ...".
#
# USAGE
#   adversarial-review.sh --repo <owner/repo> --pr <n> --rubric <file.json> \
#                         [--spec <file.md>]... [--out <dir>] [--timeout <secs>]
#
# --rubric is a JSON array of {id, question, evidence_required}.
# --spec may repeat; each file is appended inline (frozen surfaces, package JSON, whatever the
#   rubric needs to be answerable WITHOUT exploration).
#
# EXIT: 0 review produced (read <out>/review.json); non-zero per grok-run.sh's contract
#   (3 empty product, 4 timeout, 5 model non-zero, 6 stray process survived).
#
# The verdict is ADVICE, not a gate. A sonnet/human reviewer should still verify the strongest FAIL
# independently — the model has been wrong before, and an unchecked reviewer is a second opinion
# with extra steps.
set -uo pipefail

REPO=""; PR=""; RUBRIC=""; OUT=""; TMO=900; SPECS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="${2:?}"; shift ;;
    --pr) PR="${2:?}"; shift ;;
    --rubric) RUBRIC="${2:?}"; shift ;;
    --spec) SPECS+=("${2:?}"); shift ;;
    --out) OUT="${2:?}"; shift ;;
    --timeout) TMO="${2:?}"; shift ;;
    -h|--help) sed -n '2,48p' "$0"; exit 0 ;;
    *) echo "adversarial-review: unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$REPO" ] && [ -n "$PR" ] && [ -n "$RUBRIC" ] || { echo "adversarial-review: --repo, --pr and --rubric are required" >&2; exit 2; }
[ -f "$RUBRIC" ] || { echo "adversarial-review: no such rubric file: $RUBRIC" >&2; exit 2; }
command -v gh >/dev/null 2>&1 || { echo "adversarial-review: gh not on PATH" >&2; exit 2; }
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -x "$HERE/grok-run.sh" ] || { echo "adversarial-review: $HERE/grok-run.sh missing or not executable" >&2; exit 2; }

OUT="${OUT:-$(mktemp -d)}"; mkdir -p "$OUT"

# Fail loudly if the rubric is not the expected shape — a malformed rubric yields a vacuous review
# that still looks like a review, which is the failure mode this whole script exists to prevent.
python3 - "$RUBRIC" <<'PY' || exit 2
import json,sys
r=json.load(open(sys.argv[1]))
assert isinstance(r,list) and r, "rubric must be a non-empty JSON array"
for i in r:
    for k in ("id","question","evidence_required"):
        assert k in i, f"rubric item missing '{k}': {i}"
print(f"  rubric: {len(r)} items")
PY

gh pr diff "$PR" -R "$REPO" > "$OUT/diff.txt" || { echo "adversarial-review: could not fetch diff" >&2; exit 2; }
[ -s "$OUT/diff.txt" ] || { echo "adversarial-review: diff is EMPTY — refusing to review nothing" >&2; exit 2; }
gh pr view "$PR" -R "$REPO" --json title,body,additions,deletions,changedFiles > "$OUT/meta.json" 2>/dev/null

python3 - "$REPO" "$PR" "$RUBRIC" "$OUT" <<'PY'
import json,sys
repo,pr,rubric,out=sys.argv[1:5]
meta=json.load(open(f"{out}/meta.json"))
payload={
 "review_target":{"repo":repo,"pr":int(pr),"title":meta.get("title",""),
                  "additions":meta.get("additions"),"deletions":meta.get("deletions"),
                  "changed_files":meta.get("changedFiles")},
 "context":{"author_claims_from_pr_body":meta.get("body","")[:8000]},
 "rubric":json.load(open(rubric)),
 "output_contract":{
   "per_rubric_item":"verdict must be exactly one of: PASS (no problem), FAIL (real defect found), or CANNOT_DETERMINE (insufficient material provided).",
   "forbidden":"Do NOT answer with advice to 'verify X yourself' or 'if it differs, check'. All material is inline. Either determine it, or return CANNOT_DETERMINE naming the specific missing input.",
   "evidence":"Every FAIL requires a quoted line from the provided diff or spec text. An unquoted FAIL is invalid."}}
json.dump(payload,open(f"{out}/input.json","w"),indent=1)
PY

cat > "$OUT/schema.json" <<'S'
{"type":"object","additionalProperties":false,
 "required":["overall","rubric_results","unmentioned_defects","summary"],
 "properties":{
  "overall":{"enum":["APPROVE","APPROVE_WITH_NOTES","KICKBACK"]},
  "rubric_results":{"type":"array","items":{"type":"object","additionalProperties":false,
    "required":["id","verdict","evidence","reasoning"],
    "properties":{"id":{"type":"string"},"verdict":{"enum":["PASS","FAIL","CANNOT_DETERMINE"]},
      "evidence":{"type":"string"},"reasoning":{"type":"string"}}}},
  "unmentioned_defects":{"type":"array","items":{"type":"string"}},
  "summary":{"type":"string"}}}
S

{
  cat <<'B'
You are performing a STRICT RUBRIC review of one pull request. All material you need is inline below.
You must NOT explore the filesystem, clone anything, or read other repositories — everything required
is here, and wandering will exhaust your budget before you answer.

Answer EVERY rubric item. Each verdict must be exactly PASS, FAIL, or CANNOT_DETERMINE. Every FAIL
must quote a line from the provided diff or spec text; an unquoted FAIL is invalid. Do NOT reply with
"verify this yourself" or "if X differs, check Y" — determine it, or return CANNOT_DETERMINE naming
the exact missing input.

Judge the change on its merits. Credit accuracy where the author is accurate; flag it where they are
not. Do not invent findings to appear rigorous — a well-evidenced PASS is more useful than a
speculative FAIL.

=== STRUCTURED INPUT (JSON) ===
B
  cat "$OUT/input.json"
  for s in "${SPECS[@]:-}"; do
    [ -n "${s:-}" ] && [ -f "$s" ] || continue
    printf '\n=== SPEC / REFERENCE: %s ===\n' "$(basename "$s")"; cat "$s"
  done
  printf '\n=== THE DIFF UNDER REVIEW ===\n'; cat "$OUT/diff.txt"
} > "$OUT/brief.md"

echo "  brief: $(wc -c < "$OUT/brief.md") bytes -> $OUT/brief.md"
"$HERE/grok-run.sh" --brief "$OUT/brief.md" --out "$OUT/review.raw" --schema "$OUT/schema.json" --timeout "$TMO"
rc=$?
[ -f "$OUT/review.raw.json" ] && cp "$OUT/review.raw.json" "$OUT/review.json"
[ "$rc" = "0" ] && echo "  review: $OUT/review.json  ($(cat "$OUT/review.raw.status" 2>/dev/null))"
exit "$rc"
