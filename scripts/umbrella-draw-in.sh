#!/usr/bin/env bash
# Full umbrella draw-in: clone every components.lock pin at its rev and run gates.
# Simulates a user/developer installing the whole Rust train from the umbrella lock.
# Portable: Linux / macOS / Git Bash on Windows (requires git + cargo on PATH).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LOCK="${LOCK:-components.lock}"
WORKDIR="${WORKDIR:-_drawin}"
MODE="${MODE:-check}"   # check | test | check+test
FAIL_FAST="${FAIL_FAST:-1}"
PIN_LIMIT="${PIN_LIMIT:-}"
DRAW_IN_OS="${DRAW_IN_OS:-$(uname -s 2>/dev/null || echo unknown)}"
DRAW_IN_ARCH="${DRAW_IN_ARCH:-$(uname -m 2>/dev/null || echo unknown)}"

if [[ ! -f "$LOCK" ]]; then
  echo "error: missing $LOCK" >&2
  exit 2
fi
if ! command -v git >/dev/null 2>&1; then
  echo "error: git required" >&2
  exit 2
fi
if ! command -v cargo >/dev/null 2>&1; then
  echo "error: cargo required on PATH (install rustup toolchain for this OS/arch)" >&2
  exit 2
fi

PINS=()
while IFS= read -r line || [[ -n "$line" ]]; do
  case "$line" in
    *-myc=*) continue ;;
    [a-z0-9-]*=[0-9a-f]*) PINS+=("$line") ;;
  esac
done < <(grep -E '^[a-z0-9-]+=[0-9a-f]{40}' "$LOCK" || true)

if [[ ${#PINS[@]} -eq 0 ]]; then
  echo "error: no Rust pins in $LOCK" >&2
  exit 2
fi

if [[ -n "$PIN_LIMIT" ]]; then
  # portable slice
  TMP=()
  i=0
  for p in "${PINS[@]}"; do
    i=$((i + 1))
    [[ $i -le $PIN_LIMIT ]] || break
    TMP+=("$p")
  done
  PINS=("${TMP[@]}")
fi

echo "==> umbrella draw-in: ${#PINS[@]} Rust pins from $LOCK"
echo "    mode=$MODE os=$DRAW_IN_OS arch=$DRAW_IN_ARCH"
echo "    rustc: $(rustc --version 2>/dev/null || echo missing)"
mkdir -p "$WORKDIR"

ok=0
fail=0
skip=0
FAILED=()

run_gate() {
  local dir="$1"
  local name="$2"
  if [[ ! -f "$dir/Cargo.toml" ]]; then
    echo "  skip $name — no Cargo.toml (docs/seed only)"
    skip=$((skip + 1))
    return 0
  fi
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
echo "==> draw-in summary: ok=$ok fail=$fail skip=$skip os=$DRAW_IN_OS arch=$DRAW_IN_ARCH"
if [[ $fail -gt 0 ]]; then
  printf 'failed: %s\n' "${FAILED[@]}"
  exit 1
fi
if [[ $ok -eq 0 ]]; then
  echo "error: no crates checked" >&2
  exit 1
fi
echo "draw-in GREEN"
