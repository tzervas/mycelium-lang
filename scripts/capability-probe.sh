#!/usr/bin/env bash
# Measure what Mycelium can actually do, by running programs — not by asserting it in prose.
#
# WHY THIS EXISTS
# docs/EXPRESSIBILITY-GAPS.md carried MEASURED capability claims maintained by hand. Hand-
# maintained measurements rot silently, and they did: on 2026-08-03 the report still named
# `wild {}` not executing as THE critical blocker for stage S1 (mycelium-lang#16) when it had
# already been closed; it listed Process as "ABSENT (only exit) / CRITICAL" when
# process_spawn/wait/kill were registered and working; and it listed Networking as
# "ABSENT / CRITICAL" when std-net does real TLS. Planning ran off that report for days.
#
# The fix is structural rather than a promise to be more diligent: every capability claim that
# can be executed becomes a probe under probes/, this script runs them all against a real `myc`,
# and docs/CAPABILITY-MATRIX.md is GENERATED from the results and stamped with what it measured.
# Prose keeps the narrative and the prioritisation; it stops asserting status.
#
# PROBE FORMAT
# Each probes/*.myc declares its own expectations in header comments:
#   // @probe:        <stable-id>                (required, unique)
#   // @expect-check: <exit code>                (required)
#   // @expect-run:   <exit code> | skip         (required; `skip` = do not run, check only)
#   // @capability:   <short human label>        (required)
#   // @claim:        <what the docs assert>     (optional, for the drift column)
#   // @note:         <free text>                (optional, repeatable)
# A probe whose observed exit codes match its expectations is `as-expected`. A mismatch is
# `DRIFT` — either the language changed or the expectation was wrong, and both are worth a human
# look. DRIFT is a non-zero exit for this script so CI cannot ignore it.
#
# EXIT CODES OBSERVED SO FAR (myc uses sysexits)
#   0  ok        64 EX_USAGE (parse / bad invocation)   65 EX_DATAERR (check or eval refusal)
#   70 EX_SOFTWARE (elaboration residual — outside the evaluation-complete fragment)
#
# NEVER USE A PIPE TO CAPTURE AN EXIT CODE. `myc check | head` yields head's status, not myc's.
# That mistake produced a false "no change" reading during the very investigation that motivated
# this script. Everything here uses out=$(cmd 2>&1); rc=$?.
set -uo pipefail

MYC="${MYC:-myc}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROBES="$ROOT/probes"
OUT="${OUT:-$ROOT/docs/CAPABILITY-MATRIX.md}"
JSON="${JSON:-$ROOT/docs/capability-matrix.json}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

command -v "$MYC" >/dev/null 2>&1 || { echo "capability-probe: no \`$MYC\` on PATH (set MYC=/path/to/myc)" >&2; exit 1; }
[ -d "$PROBES" ] || { echo "capability-probe: no probes/ directory at $PROBES" >&2; exit 1; }

# Identify what we measured. A matrix that does not say which binary produced it is another
# undated claim, which is the whole problem.
MYC_ABS=$(command -v "$MYC")
MYC_SHA=$(sha256sum "$MYC_ABS" 2>/dev/null | cut -c1-16)
MYC_FEAT="${MYC_FEATURES:-unknown}"
STAMP="${PROBE_DATE:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

hdr() { sed -n "s|^// @$1:[[:space:]]*||p" "$2" | head -1; }

rows=""; jrows=""; drift=0; total=0; expected=0; skipped=0

for p in "$PROBES"/*.myc; do
  [ -e "$p" ] || continue
  id=$(hdr probe "$p");        [ -n "$id" ] || { echo "capability-probe: $p has no @probe id — refusing" >&2; exit 1; }
  cap=$(hdr capability "$p");  [ -n "$cap" ] || { echo "capability-probe: $id has no @capability — refusing" >&2; exit 1; }
  ec=$(hdr expect-check "$p"); er=$(hdr expect-run "$p")
  case "$ec" in ''|*[!0-9]*) echo "capability-probe: $id has no numeric @expect-check — refusing" >&2; exit 1 ;; esac
  case "$er" in ''|skip) : ;; *[!0-9]*) echo "capability-probe: $id @expect-run must be a number or 'skip'" >&2; exit 1 ;; esac
  claim=$(hdr claim "$p")
  req=$(hdr requires "$p")

  # Skip probes whose environmental requirement this run cannot satisfy, and say so in the
  # matrix rather than counting them as drift. The rootless CI runners generally have no
  # outbound egress (the `standards` workflow already fails its PyYAML install for that
  # reason), so a network probe would otherwise report DRIFT for an environmental reason and
  # train everyone to ignore the gate. A skipped row is honest; a false DRIFT is corrosive.
  if [ -n "$req" ] && [ -n "${PROBE_SKIP_REQUIRES:-}" ]; then
    case ",$PROBE_SKIP_REQUIRES," in
      *",$req,"*)
        total=$((total+1)); skipped=$((skipped+1))
        rows="$rows| \`$id\` | $cap | $ec / $er | — / — | skipped (requires \`$req\`) | not measured in this environment |
"
        jrows="$jrows{\"probe\":\"$id\",\"capability\":\"$cap\",\"status\":\"skipped\",\"requires\":\"$req\"},"
        continue ;;
    esac
  fi
  total=$((total+1))

  # Each probe gets its own scaffolded project so nothing leaks between them.
  d="$WORK/$id"; mkdir -p "$d"
  ( cd "$d" && "$MYC" init pj >/dev/null 2>&1 )
  cp "$p" "$d/pj/pj.myc"
  # The nodule name must match what `myc init` scaffolded, so rewrite the header's name only.
  sed -i "s/^nodule [A-Za-z0-9_-]*/nodule pj/" "$d/pj/pj.myc"

  cout=$( cd "$d/pj" && "$MYC" check 2>&1 ); crc=$?
  if [ "$er" = "skip" ]; then rout="(not run)"; rrc="$er"
  else rout=$( cd "$d/pj" && "$MYC" run 2>&1 ); rrc=$?
  fi

  ok="yes"
  [ "$crc" = "$ec" ] || ok="no"
  [ "$er" = "skip" ] || [ "$rrc" = "$er" ] || ok="no"
  if [ "$ok" = "yes" ]; then expected=$((expected+1)); mark="as-expected"
  else mark="**DRIFT**"; drift=$((drift+1)); fi

  # First diagnostic line, squeezed to one cell. The layer that refused matters more than the code.
  diag=$(printf '%s\n%s\n' "$cout" "$rout" | grep -oE 'error\[[a-z0-9-]+\][^|]*' | head -1 | cut -c1-96)
  [ -n "$diag" ] || diag="—"
  rows="$rows| \`$id\` | $cap | $ec / $er | $crc / $rrc | $mark | ${diag//|/\\|} |
"
  jrows="$jrows{\"probe\":\"$id\",\"capability\":\"$cap\",\"expect_check\":\"$ec\",\"expect_run\":\"$er\",\"got_check\":\"$crc\",\"got_run\":\"$rrc\",\"status\":\"$([ "$ok" = yes ] && echo as-expected || echo drift)\",\"claim\":\"$(printf '%s' "$claim" | sed 's/"/\\"/g')\"},"
done

mkdir -p "$(dirname "$OUT")"
{
  cat <<EOF
<!-- GENERATED by scripts/capability-probe.sh — DO NOT EDIT BY HAND. -->
<!-- Narrative and prioritisation live in EXPRESSIBILITY-GAPS.md; this file is measurement only. -->
# Mycelium capability matrix (measured)

| Field | Value |
|-------|-------|
| **Measured** | $STAMP |
| **Binary** | \`$MYC_ABS\` (sha256 \`$MYC_SHA…\`) |
| **Cargo features** | \`$MYC_FEAT\` |
| **Probes** | $total ($expected as-expected, $drift drift, $skipped skipped) |

Every row below was produced by running a program in \`probes/\`. Nothing here is asserted.
\`expect\` is what the probe declares; \`got\` is what this run observed. **DRIFT** means the two
disagree — either the language moved or the expectation was wrong, and both need a human.

Exit codes are sysexits: \`0\` ok, \`64\` EX_USAGE (parse), \`65\` EX_DATAERR (check or eval
refusal), \`70\` EX_SOFTWARE (elaboration residual — outside the evaluation-complete fragment).

| probe | capability | expect check/run | got check/run | status | first diagnostic |
|-------|-----------|------------------|---------------|--------|------------------|
EOF
  printf '%s' "$rows"
  cat <<EOF

## How to add a capability claim

Write a probe, do not write a sentence. \`probes/<id>.myc\` with the \`@probe\`, \`@capability\`,
\`@expect-check\` and \`@expect-run\` headers, then run \`MYC=/path/to/myc scripts/capability-probe.sh\`.
If a claim cannot be expressed as a program, that inexpressibility is itself the finding and
belongs in the narrative doc with an explicit "not probe-able" note — never as an unmeasured
status claim, which is exactly how this document's predecessor went stale.
EOF
} > "$OUT"

printf '{"measured":"%s","binary_sha256_16":"%s","features":"%s","total":%s,"as_expected":%s,"drift":%s,"skipped":%s,"probes":[%s]}\n' \
  "$STAMP" "$MYC_SHA" "$MYC_FEAT" "$total" "$expected" "$drift" "$skipped" "${jrows%,}" > "$JSON"

echo "capability-probe: $total probes, $expected as-expected, $drift drift, $skipped skipped"
echo "capability-probe: wrote $OUT and $JSON"
# Drift fails loudly. A matrix that silently absorbs a behaviour change is the original bug.
[ "$drift" -eq 0 ] || { echo "::warning title=capability drift::$drift probe(s) no longer match their declared expectations"; exit 2; }
