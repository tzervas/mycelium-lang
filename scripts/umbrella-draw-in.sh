#!/usr/bin/env bash
# Full umbrella draw-in: clone every components.lock pin at its rev and run gates.
# Simulates a user/developer installing the whole Rust train from the umbrella lock.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LOCK="${LOCK:-components.lock}"
WORKDIR="${WORKDIR:-_drawin}"
MODE="${MODE:-check}"   # check | test | check+test
FAIL_FAST="${FAIL_FAST:-1}"
KEEP="${KEEP:-1}"

if [[ ! -f "$LOCK" ]]; then
  echo "error: missing $LOCK" >&2
  exit 2
fi

mapfile -t PINS < <(grep -E '^[a-z0-9-]+=[0-9a-f]{40}' "$LOCK" | grep -v -- '-myc=')
if [[ ${#PINS[@]} -eq 0 ]]; then
  echo "error: no Rust pins in $LOCK" >&2
  exit 2
fi

echo "==> umbrella draw-in: ${#PINS[@]} Rust pins from $LOCK (mode=$MODE)"
mkdir -p "$WORKDIR"

ok=0
fail=0
skip=0
declare -a FAILED

run_gate() {
  local dir="$1"
  local name="$2"
  if [[ ! -f "$dir/Cargo.toml" ]]; then
    echo "  skip $name — no Cargo.toml (docs/seed only)"
    skip=$((skip + 1))
    return 0
  fi
  case "$MODE" in
    check)
      (cd "$dir" && cargo check --workspace --all-targets)
      ;;
    test)
      (cd "$dir" && cargo test --workspace)
      ;;
    check+test)
      (cd "$dir" && cargo check --workspace --all-targets)
      (cd "$dir" && cargo test --workspace)
      ;;
    *)
      echo "error: unknown MODE=$MODE" >&2
      return 2
      ;;
  esac
}

for line in "${PINS[@]}"; do
  name="${line%%=*}"
  rest="${line#*=}"
  rev="${rest%% *}"
  rev="${rev%%tree=*}"
  rev="$(echo "$rev" | tr -d '[:space:]')"
  echo "---- $name @ $rev ----"
  dest="$WORKDIR/$name"
  if [[ ! -d "$dest/.git" ]]; then
    git clone -q "https://github.com/tzervas/${name}.git" "$dest"
  fi
  git -C "$dest" fetch -q --depth 1 origin "$rev" 2>/dev/null \
    || git -C "$dest" fetch -q origin "$rev"
  git -C "$dest" checkout -q "$rev"

  if run_gate "$dest" "$name"; then
    echo "  OK $name@$rev"
    ok=$((ok + 1))
  else
    echo "  FAIL $name@$rev" >&2
    FAILED+=("$name@$rev")
    fail=$((fail + 1))
    if [[ "$FAIL_FAST" == "1" ]]; then
      break
    fi
  fi
done

echo
echo "==> draw-in summary: ok=$ok fail=$fail skip=$skip total=${#PINS[@]}"
if [[ $fail -gt 0 ]]; then
  printf 'failed: %s\n' "${FAILED[@]}"
  exit 1
fi
if [[ $ok -eq 0 ]]; then
  echo "error: no crates checked" >&2
  exit 1
fi
echo "draw-in GREEN"
