#!/usr/bin/env bash
# Install templates/fleet-notify.yml into every component repo in components.lock,
# one conventional-commit PR per repo, auto-merge armed.
#
# OPTIONAL. The umbrella's schedule already catches every advance; this only
# removes latency, at the cost of one FLEET_DISPATCH_TOKEN secret per repo.
#
# Dry-run by default. Set APPLY=1 to actually push and open PRs.
#
#   bash scripts/rollout-fleet-notify.sh              # show what would happen
#   APPLY=1 bash scripts/rollout-fleet-notify.sh      # do it
#   APPLY=1 ONLY=mycelium-core,mycelium-l1 bash scripts/rollout-fleet-notify.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="${LOCK:-$ROOT/components.lock}"
TEMPLATE="${TEMPLATE:-$ROOT/templates/fleet-notify.yml}"
APPLY="${APPLY:-0}"
ONLY="${ONLY:-}"
BRANCH="${BRANCH:-ci/fleet-notify}"
OWNER=tzervas

[ -f "$TEMPLATE" ] || { echo "error: missing $TEMPLATE" >&2; exit 2; }
command -v gh >/dev/null || { echo "error: gh required" >&2; exit 2; }

want() {
  [ -z "$ONLY" ] && return 0
  case ",$ONLY," in *,"$1",*) return 0;; *) return 1;; esac
}

repos=$(grep -oE '^[a-z0-9-]+(?==)' "$LOCK" 2>/dev/null || grep -E '^[a-z0-9-]+=[0-9a-f]{40}' "$LOCK" | cut -d= -f1)

n=0; skipped=0
for r in $repos; do
  want "$r" || continue

  # Idempotent: never open a second PR for a repo that already has the workflow.
  if gh api "repos/$OWNER/$r/contents/.github/workflows/fleet-notify.yml" >/dev/null 2>&1; then
    echo "skip  $r (already installed)"
    skipped=$((skipped + 1))
    continue
  fi

  if [ "$APPLY" != "1" ]; then
    echo "would install -> $r"
    n=$((n + 1))
    continue
  fi

  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  git clone -q --depth 1 "https://github.com/$OWNER/$r.git" "$tmp/$r"
  mkdir -p "$tmp/$r/.github/workflows"
  cp "$TEMPLATE" "$tmp/$r/.github/workflows/fleet-notify.yml"

  git -C "$tmp/$r" checkout -q -b "$BRANCH"
  git -C "$tmp/$r" add -A
  git -C "$tmp/$r" -c user.name=fleet-propagate -c user.email=noreply@github.com \
    commit -q -m "ci(fleet): notify the umbrella when this component advances

Fires repository_dispatch component-advanced at tzervas/mycelium-lang on push to
main and on release publish, so coordinated revision propagation starts within
seconds instead of waiting for the umbrella's 2-hourly backstop schedule.

No-op with a warning if FLEET_DISPATCH_TOKEN is unset — the umbrella's schedule
still catches the advance, so a missing secret degrades latency, not correctness."
  git -C "$tmp/$r" push -q -u origin "$BRANCH"

  gh pr create --repo "$OWNER/$r" --base main --head "$BRANCH" \
    --title "ci(fleet): notify the umbrella when this component advances" \
    --body "Installs \`.github/workflows/fleet-notify.yml\` from \`tzervas/mycelium-lang\`.

Fires \`repository_dispatch\` \`component-advanced\` at the umbrella on push to \`main\` and on release publish, so coordinated revision propagation starts promptly rather than waiting for the 2-hourly backstop schedule.

CI-only; no source, manifest, or pin is touched. If \`FLEET_DISPATCH_TOKEN\` is unset the job warns and exits 0 — the umbrella's schedule still catches the advance, so a missing secret costs latency, not correctness." >/dev/null
  gh pr merge --repo "$OWNER/$r" --auto --squash "$BRANCH" >/dev/null 2>&1 ||
    echo "  warn: auto-merge not armed for $r"
  echo "opened PR -> $r"
  n=$((n + 1))
done

echo
echo "repos processed: $n   already installed: $skipped   apply=$APPLY"
[ "$APPLY" = "1" ] || echo "dry run — set APPLY=1 to push and open PRs"
