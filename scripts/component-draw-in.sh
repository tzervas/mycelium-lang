#!/usr/bin/env bash
# Validate ONE component repo the way a developer would: checkout pin, cargo check/test.
# Usable:
#   From umbrella:  COMPONENT=mycelium-core bash scripts/component-draw-in.sh
#   From a clone:   bash scripts/component-draw-in.sh   # uses cwd + optional COMPONENT_REV
set -euo pipefail

MODE="${MODE:-check}"          # check | test | check+test
COMPONENT="${COMPONENT:-}"
COMPONENT_REV="${COMPONENT_REV:-}"
WORKDIR="${WORKDIR:-_drawin_one}"
DRAW_IN_OS="${DRAW_IN_OS:-$(uname -s 2>/dev/null || echo unknown)}"
DRAW_IN_ARCH="${DRAW_IN_ARCH:-$(uname -m 2>/dev/null || echo unknown)}"

if [[ -n "$COMPONENT" ]]; then
  # Umbrella mode — resolve pin from components.lock
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  LOCK="${LOCK:-$ROOT/components.lock}"
  if [[ ! -f "$LOCK" ]]; then
    echo "error: components.lock not found at $LOCK" >&2
    exit 2
  fi
  line="$(grep -E "^${COMPONENT}=" "$LOCK" || true)"
  if [[ -z "$line" ]]; then
    echo "error: $COMPONENT not in $LOCK" >&2
    exit 2
  fi
  rest="${line#*=}"
  rev="${rest%% *}"
  rev="${rev%%tree=*}"
  rev="$(echo "$rev" | tr -d '[:space:]')"
  mkdir -p "$WORKDIR"
  dest="$WORKDIR/$COMPONENT"
  if [[ ! -d "$dest/.git" ]]; then
    git clone -q "https://github.com/tzervas/${COMPONENT}.git" "$dest"
  fi
  git -C "$dest" fetch -q --depth 1 origin "$rev" 2>/dev/null || git -C "$dest" fetch -q origin "$rev"
  git -C "$dest" checkout -q "$rev"
  DIR="$dest"
  NAME="$COMPONENT"
  echo "==> component draw-in: $NAME @ $rev (from lock)"
else
  DIR="$(pwd)"
  NAME="$(basename "$DIR")"
  rev="$(git -C "$DIR" rev-parse HEAD 2>/dev/null || echo unknown)"
  if [[ -n "$COMPONENT_REV" && "$rev" != "unknown" ]]; then
    git -C "$DIR" checkout -q "$COMPONENT_REV"
    rev="$COMPONENT_REV"
  fi
  echo "==> component draw-in: $NAME @ $rev (cwd)"
fi

echo "    mode=$MODE os=$DRAW_IN_OS arch=$DRAW_IN_ARCH"
echo "    rustc: $(rustc --version 2>/dev/null || echo missing)"

if [[ ! -f "$DIR/Cargo.toml" ]]; then
  echo "skip: no Cargo.toml in $NAME (docs/seed only) — still a valid component surface"
  exit 0
fi

case "$MODE" in
  check) (cd "$DIR" && cargo check --workspace --all-targets) ;;
  test) (cd "$DIR" && cargo test --workspace) ;;
  check+test)
    (cd "$DIR" && cargo check --workspace --all-targets)
    (cd "$DIR" && cargo test --workspace)
    ;;
  *) echo "error: unknown MODE=$MODE" >&2; exit 2 ;;
esac

echo "component draw-in GREEN: $NAME"
