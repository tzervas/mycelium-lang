#!/usr/bin/env bash
# Offload one unit of work to the LOCAL grok CLI, capture the product to a file, and guarantee
# nothing is left dangling.
#
# WHY LOCAL AND NOT agent-mcp
# agent-mcp's `grok` provider is browser/cloud-driven and fails with
#   "authentication failed for provider grok: Login timeout - please complete authentication manually"
# It needs an interactive browser login a background session cannot complete (observed 3x).
# The LOCAL CLI at ~/.local/bin/grok -> ~/.grok/bin/grok is authenticated and works headlessly:
#   grok -p "<prompt>" --output-format plain --max-turns 1   ->  "ALIVE", exit 0
#
# REAPING IS THE POINT
# grok is an agentic TUI that can spawn subagents and keeps a leader process on
# ~/.grok/leader.sock. "It printed output" does NOT mean "nothing is still running". So:
#   - the child runs in its OWN process group (setsid) so the whole tree can be signalled
#   - `timeout` bounds the runaway case
#   - on exit we TERM the group, grace, then KILL the group, and VERIFY by PID that it is gone
#   - we never use `pkill -f grok`: this script's own command line contains the word, so a
#     pattern kill would match the wrapper (and any other session's grok). That self-match
#     mistake has already killed a shell in this project. Kill by PGID only.
#
# USAGE
#   grok-run.sh --brief <file> --out <file> [--schema <file>] [--timeout <secs>]
#               [--cwd <dir>] [--model <id>] [--effort <low|medium|high>]
#
# CONTRACT
#   Writes <out>            the product (plain text, or JSON if --schema given)
#          <out>.err        stderr
#          <out>.status     one line: EXIT=<code> ELAPSED=<secs> REAPED=<yes|no>
#   exit 0   grok exited 0 and the product is non-empty
#   exit 3   grok exited 0 but produced an EMPTY product (a silent no-answer — never treat as success)
#   exit 4   timed out
#   exit 5   grok exited non-zero
#   exit 6   completed but a stray process survived reaping (surfaced, never hidden)
set -uo pipefail

BRIEF=""; OUT=""; SCHEMA=""; TMO=900; CWD="$PWD"; MODEL=""; EFFORT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --brief)   BRIEF="${2:?}"; shift ;;
    --out)     OUT="${2:?}"; shift ;;
    --schema)  SCHEMA="${2:?}"; shift ;;
    --timeout) TMO="${2:?}"; shift ;;
    --cwd)     CWD="${2:?}"; shift ;;
    --model)   MODEL="${2:?}"; shift ;;
    --effort)  EFFORT="${2:?}"; shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "grok-run: unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$BRIEF" ] && [ -f "$BRIEF" ] || { echo "grok-run: --brief <existing file> required" >&2; exit 2; }
[ -n "$OUT" ] || { echo "grok-run: --out <file> required" >&2; exit 2; }

# Absolutize every path BEFORE grok is invoked. --cwd changes grok's working directory, so a
# relative --prompt-file/--json-schema resolves against the TARGET dir, not the caller's — which
# fails with a bare "No such file or directory" that looks like a missing brief rather than a
# path-resolution bug. Outputs are absolutized too so redirections land where the caller expects.
abspath(){ case "$1" in /*) printf '%s\n' "$1" ;; *) printf '%s/%s\n' "$(pwd)" "$1" ;; esac; }
BRIEF=$(abspath "$BRIEF")
OUT=$(abspath "$OUT")
[ -n "$SCHEMA" ] && SCHEMA=$(abspath "$SCHEMA")
[ -d "$CWD" ] || { echo "grok-run: --cwd is not a directory: $CWD" >&2; exit 2; }
CWD=$(cd "$CWD" && pwd)
command -v grok >/dev/null 2>&1 || { echo "grok-run: no \`grok\` on PATH" >&2; exit 2; }

ERR="$OUT.err"; ST="$OUT.status"
: > "$OUT"; : > "$ERR"; : > "$ST"

ARGS=( --prompt-file "$BRIEF" --max-turns 8 --cwd "$CWD" )
# Read-only by default. The product comes back for OUR review, patching and promotion -- grok
# should not be editing repos or pushing on its own. Explicitly deny the mutating tools rather
# than trusting a default.
ARGS+=( --permission-mode default --disallowed-tools "Write,Edit,NotebookEdit" )
if [ -n "$SCHEMA" ]; then
  [ -f "$SCHEMA" ] || { echo "grok-run: --schema file not found: $SCHEMA" >&2; exit 2; }
  ARGS+=( --output-format json --json-schema "$(cat "$SCHEMA")" )
else
  ARGS+=( --output-format plain )
fi
[ -n "$MODEL" ]  && ARGS+=( --model "$MODEL" )
[ -n "$EFFORT" ] && ARGS+=( --effort "$EFFORT" )

START=$(date +%s)

# Own process group so the entire tree (grok + any subagents it spawns) is signallable.
setsid timeout -k 15 "$TMO" grok "${ARGS[@]}" >"$OUT" 2>"$ERR" &
CHILD=$!
# The PGID equals the setsid child's PID.
PGID="$CHILD"

wait "$CHILD"; RC=$?
ELAPSED=$(( $(date +%s) - START ))

# ---------------------------------------------------------------------------
# Reap. Signal the GROUP, by id -- never by name pattern.
# ---------------------------------------------------------------------------
REAPED="yes"
if kill -0 -- "-$PGID" 2>/dev/null; then
  kill -TERM -- "-$PGID" 2>/dev/null
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    kill -0 -- "-$PGID" 2>/dev/null || break
    sleep 1
  done
  if kill -0 -- "-$PGID" 2>/dev/null; then
    kill -KILL -- "-$PGID" 2>/dev/null
    sleep 1
  fi
  if kill -0 -- "-$PGID" 2>/dev/null; then REAPED="no"; fi
fi

# In JSON mode grok wraps the answer. The schema-constrained object is available BOTH as
# `.structuredOutput` (an object) and as `.text` (the same thing JSON-encoded as a string).
# Prefer .structuredOutput -- reaching through .text needs a double parse and is easy to get
# wrong. Emit the unwrapped object to <out>.json so a consumer never has to know either shape.
COST=""; TURNS=""
if [ -n "$SCHEMA" ] && [ -s "$OUT" ]; then
  python3 - "$OUT" "$OUT.json" <<'PY' 2>/dev/null || echo "grok-run: could not unwrap structuredOutput (see $OUT)" >&2
import json,sys
raw=json.load(open(sys.argv[1]))
obj=raw.get("structuredOutput")
if obj is None and isinstance(raw.get("text"),str):
    try: obj=json.loads(raw["text"])
    except Exception: obj=None
if obj is None: raise SystemExit(1)
json.dump(obj, open(sys.argv[2],"w"), indent=1)
PY
  COST=$(python3 -c "import json;print(json.load(open('$OUT')).get('total_cost_usd',''))" 2>/dev/null)
  TURNS=$(python3 -c "import json;print(json.load(open('$OUT')).get('num_turns',''))" 2>/dev/null)
fi

printf 'EXIT=%s ELAPSED=%ss REAPED=%s COST_USD=%s TURNS=%s\n' \
  "$RC" "$ELAPSED" "$REAPED" "${COST:-na}" "${TURNS:-na}" > "$ST"

# 124 is timeout(1)'s signal that it fired.
if [ "$RC" = "124" ] || [ "$RC" = "137" ]; then
  echo "grok-run: TIMED OUT after ${TMO}s (rc=$RC)" >&2; exit 4
fi
if [ "$RC" != "0" ]; then
  echo "grok-run: grok exited $RC — see $ERR" >&2; exit 5
fi
# A zero exit with an empty product is a silent no-answer. Refuse to call it success.
if [ ! -s "$OUT" ]; then
  echo "grok-run: grok exited 0 but produced an EMPTY product — treating as failure" >&2; exit 3
fi
if [ "$REAPED" != "yes" ]; then
  echo "grok-run: product captured but a process in group $PGID survived — investigate" >&2; exit 6
fi
echo "grok-run: ok — ${ELAPSED}s, $(wc -c < "$OUT") bytes -> $OUT"
