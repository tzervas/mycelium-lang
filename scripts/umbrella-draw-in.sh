#!/usr/bin/env bash
# Full umbrella draw-in: for EVERY Rust pin in components.lock (each is a
# tzervas/* component repo), clone at the locked rev and run cargo gates.
# This is component-first validation aggregated by the umbrella lock — not a
# check of the umbrella tree itself (which has no Cargo.toml).
#
# Portable: Linux / macOS / Git Bash on Windows (git + cargo on PATH).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LOCK="${LOCK:-components.lock}"
WORKDIR="${WORKDIR:-_drawin}"
MODE="${MODE:-check}"   # check | test | check+test
FAIL_FAST="${FAIL_FAST:-1}"
PIN_LIMIT="${PIN_LIMIT:-}"
# Optional: only these components (comma-separated). Empty = all pins.
ONLY_COMPONENTS="${ONLY_COMPONENTS:-}"
DRAW_IN_OS="${DRAW_IN_OS:-$(uname -s 2>/dev/null || echo unknown)}"
DRAW_IN_ARCH="${DRAW_IN_ARCH:-$(uname -m 2>/dev/null || echo unknown)}"
REPORT_JSONL="${REPORT_JSONL:-}"

if [[ ! -f "$LOCK" ]]; then
  echo "error: missing $LOCK" >&2
  exit 2
fi
if ! command -v git >/dev/null 2>&1; then
  echo "error: git required" >&2
  exit 2
fi
if ! command -v cargo >/dev/null 2>&1; then
  echo "error: cargo required on PATH" >&2
  exit 2
fi

want_component() {
  local name="$1"
  [[ -z "$ONLY_COMPONENTS" ]] && return 0
  case ",${ONLY_COMPONENTS}," in
    *,"$name",*) return 0 ;;
    *) return 1 ;;
  esac
}

PINS=()
while IFS= read -r line || [[ -n "${line:-}" ]]; do
  case "$line" in
    *-myc=*) continue ;;
    [a-z0-9-]*=[0-9a-f]*) PINS+=("$line") ;;
  esac
done < <(grep -E '^[a-z0-9-]+=[0-9a-f]{40}' "$LOCK" || true)

if [[ ${#PINS[@]} -eq 0 ]]; then
  echo "error: no Rust pins in $LOCK" >&2
  exit 2
fi

FILTERED=()
for line in "${PINS[@]}"; do
  name="${line%%=*}"
  want_component "$name" || continue
  FILTERED+=("$line")
done
PINS=("${FILTERED[@]}")

if [[ -n "$PIN_LIMIT" ]]; then
  TMP=()
  i=0
  for p in "${PINS[@]}"; do
    i=$((i + 1))
    [[ $i -le $PIN_LIMIT ]] || break
    TMP+=("$p")
  done
  PINS=("${TMP[@]}")
fi

echo "==> component draw-in via umbrella lock: ${#PINS[@]} component repo(s)"
echo "    mode=$MODE os=$DRAW_IN_OS arch=$DRAW_IN_ARCH"
echo "    rustc: $(rustc --version 2>/dev/null || echo missing)"
echo "    each pin = https://github.com/tzervas/<component> @ locked rev"
mkdir -p "$WORKDIR"
if [[ -n "$REPORT_JSONL" ]]; then
  : >"$REPORT_JSONL"
fi

emit_report() {
  local name="$1" rev="$2" status="$3" detail="${4:-}"
  [[ -z "$REPORT_JSONL" ]] && return 0
  # minimal JSON (names are [a-z0-9-], revs hex)
  printf '{"component":"%s","rev":"%s","status":"%s","detail":"%s","os":"%s","arch":"%s","mode":"%s"}\n' \
    "$name" "$rev" "$status" "$detail" "$DRAW_IN_OS" "$DRAW_IN_ARCH" "$MODE" >>"$REPORT_JSONL"
}

ok=0
fail=0
skip=0
FAILED=()

run_gate() {
  local dir="$1"
  case "$MODE" in
    check) (cd "$dir" && cargo check --workspace --all-targets) ;;
    test) (cd "$dir" && cargo test --workspace) ;;
    check+test)
      (cd "$dir" && cargo check --workspace --all-targets)
      (cd "$dir" && cargo test --workspace)
      ;;
    *) echo "error: unknown MODE=$MODE" >&2; return 2 ;;
  esac
}

for line in "${PINS[@]}"; do
  name="${line%%=*}"
  rest="${line#*=}"
  rev="${rest%% *}"
  rev="${rev%%tree=*}"
  rev="$(echo "$rev" | tr -d '[:space:]')"
  echo "==== component repo: tzervas/${name} @ ${rev} ===="
  dest="$WORKDIR/$name"
  if [[ ! -d "$dest/.git" ]]; then
    git clone -q "https://github.com/tzervas/${name}.git" "$dest"
  fi
  git -C "$dest" fetch -q --depth 1 origin "$rev" 2>/dev/null \
    || git -C "$dest" fetch -q origin "$rev"
  git -C "$dest" checkout -q "$rev"

  if [[ ! -f "$dest/Cargo.toml" ]]; then
    echo "  skip $name — no Cargo.toml (docs/seed only)"
    skip=$((skip + 1))
    emit_report "$name" "$rev" "skip" "no Cargo.toml"
    continue
  fi

  if run_gate "$dest"; then
    echo "  OK component $name@$rev"
    ok=$((ok + 1))
    emit_report "$name" "$rev" "ok" ""
  else
    echo "  FAIL component $name@$rev" >&2
    FAILED+=("$name@$rev")
    fail=$((fail + 1))
    emit_report "$name" "$rev" "fail" "cargo gate"
    if [[ "$FAIL_FAST" == "1" ]]; then
      break
    fi
  fi
done

echo
echo "==> component draw-in summary: ok=$ok fail=$fail skip=$skip os=$DRAW_IN_OS arch=$DRAW_IN_ARCH"
if [[ -n "$REPORT_JSONL" ]]; then
  echo "    report: $REPORT_JSONL ($(wc -l <"$REPORT_JSONL") lines)"
fi
if [[ $fail -gt 0 ]]; then
  printf 'failed components: %s\n' "${FAILED[@]}"
  exit 1
fi
if [[ $ok -eq 0 && $skip -eq 0 ]]; then
  echo "error: no components checked" >&2
  exit 1
fi
echo "component draw-in GREEN"
