#!/usr/bin/env python3
"""Coordinated cross-repo revision propagation for the Mycelium Rust train.

The existing draw-in scripts *validate* the pins in ``components.lock``. Nothing
*advances* them. That asymmetry is why work can land green in a component repo
and remain invisible to all 45 lock pins and every sibling ``rev =`` dependency.
This tool closes that half.

The fleet is a DAG: 46 component repos joined by ~126 sibling git dependencies,
each pinned by an explicit 40-char ``rev``. Advancing one repo therefore forces a
Cargo.toml edit in every dependent, whose own HEAD then moves, forcing another
round. Propagation is inherently **wave-structured**, and the wave count equals
the depth of the DAG. Doing that by hand is the "unsustainable manual tax".

Subcommands
-----------
``plan``    Resolve targets, compute waves, print exactly what would change.
            Read-only. Always run this first.
``apply``   Open one PR per repo for a single wave (``--wave N``). Never pushes
            to a protected branch; never merges.
``lock``    Regenerate ``components.lock`` from resolved revs + tree hashes.

Everything is driven off the live GitHub state, not a local checkout, so a stale
working copy cannot silently produce a wrong plan.

Examples
--------
    python3 scripts/fleet-propagate.py plan
    python3 scripts/fleet-propagate.py plan --ref dev --only mycelium-runtime,mycelium-codegen
    python3 scripts/fleet-propagate.py apply --wave 0
    python3 scripts/fleet-propagate.py lock --write
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from collections import defaultdict

OWNER = "tzervas"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOCK = os.path.join(ROOT, "components.lock")

# name = { git = "https://github.com/tzervas/<repo>", rev = "<40 hex>" }
RE_DEP = re.compile(
    r'(?P<head>^\s*[a-z0-9_-]+\s*=\s*\{[^}]*?git\s*=\s*"https://github\.com/'
    r'tzervas/(?P<repo>[a-z0-9-]+)"[^}]*?rev\s*=\s*")(?P<rev>[0-9a-f]{40})',
    re.M,
)
RE_LOCK_PIN = re.compile(r"^(?P<name>[a-z0-9-]+)=(?P<rev>[0-9a-f]{40})(?:\s+tree=(?P<tree>[0-9a-f]{40}))?")


# ---------------------------------------------------------------- github I/O

def gh(*args: str) -> str:
    """Call `gh api` and return stdout, or "" on failure."""
    try:
        r = subprocess.run(["gh", "api", *args], capture_output=True, text=True, timeout=90)
        return r.stdout.strip() if r.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        return ""


def head_of(repo: str, ref: str) -> str:
    return gh(f"repos/{OWNER}/{repo}/commits/{ref}", "--jq", ".sha")


def tree_of(repo: str, rev: str) -> str:
    return gh(f"repos/{OWNER}/{repo}/commits/{rev}", "--jq", ".commit.tree.sha")


def file_at(repo: str, path: str, ref: str) -> str | None:
    """Fetch a text file at a ref via the contents API."""
    import base64
    raw = gh(f"repos/{OWNER}/{repo}/contents/{path}?ref={ref}", "--jq", ".content")
    if not raw:
        return None
    try:
        return base64.b64decode(raw).decode("utf-8", "replace")
    except (ValueError, TypeError):
        return None


def manifests_at(repo: str, ref: str) -> list[str]:
    """Paths of every Cargo.toml in the repo at ``ref`` (via the git tree API)."""
    out = gh(f"repos/{OWNER}/{repo}/git/trees/{ref}?recursive=1",
             "--jq", '.tree[] | select(.path | endswith("Cargo.toml")) | .path')
    return [p for p in out.splitlines() if p and "/target/" not in p]


# ------------------------------------------------------------------- lock io

def read_lock() -> tuple[list[str], dict[str, dict]]:
    lines = open(LOCK, encoding="utf-8").read().splitlines()
    pins: dict[str, dict] = {}
    for ln in lines:
        m = RE_LOCK_PIN.match(ln)
        if m:
            pins[m.group("name")] = {"rev": m.group("rev"), "tree": m.group("tree")}
    return lines, pins


# ----------------------------------------------------------------- the graph

def build_state(repos: list[str], ref: str, verbose: bool = True) -> dict:
    """Resolve each repo's target rev and its sibling dependency edges."""
    state: dict[str, dict] = {}
    for i, r in enumerate(repos, 1):
        if verbose:
            print(f"  [{i:>2}/{len(repos)}] {r}", file=sys.stderr)
        target = head_of(r, ref) or head_of(r, "main")
        deps: dict[str, set[str]] = defaultdict(set)
        files: dict[str, str] = {}
        for path in manifests_at(r, target):
            txt = file_at(r, path, target)
            if not txt:
                continue
            found = [(m.group("repo"), m.group("rev")) for m in RE_DEP.finditer(txt)]
            if found:
                files[path] = txt
                for dep, rev in found:
                    deps[dep].add(rev)
        state[r] = {"target": target, "deps": {k: sorted(v) for k, v in deps.items()},
                    "manifests": files}
    return state


def compute_waves(state: dict) -> tuple[dict[str, int], dict[str, list]]:
    """wave(r) = 0 if no dep needs bumping, else 1 + max(wave(changed deps)).

    A repo lands in wave N because its dependency's *own* HEAD only moves once
    that dependency's wave-(N-1) PR merges. This is the real serialisation cost.
    """
    edits: dict[str, list] = {}
    for r, s in state.items():
        need = []
        for dep, revs in s["deps"].items():
            if dep not in state:
                continue
            want = state[dep]["target"]
            for cur in revs:
                if cur != want:
                    need.append({"dep": dep, "from": cur, "to": want})
        edits[r] = need

    wave: dict[str, int] = {}

    def resolve(r: str, stack: tuple = ()) -> int:
        if r in wave:
            return wave[r]
        if r in stack:            # cycles are impossible here, but never hang
            return 0
        if not edits.get(r):
            wave[r] = 0
            return 0
        w = 1 + max((resolve(e["dep"], stack + (r,)) for e in edits[r]), default=-1)
        wave[r] = w
        return w

    for r in state:
        resolve(r)
    return wave, edits


# --------------------------------------------------------------- invariant

def check_invariant(state: dict) -> int:
    """Every sibling must be pinned at exactly ONE rev across the whole fleet.

    Cargo treats the same git URL at two different revs as two distinct source
    ids, so a sibling pinned at two revs yields two copies of that crate in one
    build graph — and any type crossing the boundary fails to unify. Holding one
    rev per sibling is therefore load-bearing, not merely tidy.

    It is also the reason propagation must cascade: advancing every pin to its
    dependency's *current* HEAD in a single shot would transiently pin some
    sibling at two revs, because a dependency's own bump commit has not landed
    yet.
    """
    seen: dict[str, set[str]] = defaultdict(set)
    where: dict[tuple[str, str], list[str]] = defaultdict(list)
    for r, s in state.items():
        for dep, revs in s["deps"].items():
            for rev in revs:
                seen[dep].add(rev)
                where[(dep, rev)].append(r)
    conflicts = {d: v for d, v in seen.items() if len(v) > 1}
    print(f"sibling deps referenced fleet-wide : {len(seen)}")
    print(f"deps pinned at >1 distinct rev     : {len(conflicts)}")
    for dep, revs in sorted(conflicts.items()):
        print(f"  CONFLICT {dep}:")
        for rev in sorted(revs):
            print(f"    {rev[:8]}  <- {', '.join(sorted(where[(dep, rev)]))}")
    if conflicts:
        print("\nA sibling pinned at two revs puts two copies of that crate in one "
              "cargo graph.\nThis must be resolved before propagating.")
        return 1
    print("OK — single-version invariant holds.")
    return 0


# -------------------------------------------------------------------- apply

def run(cmd: list[str], cwd: str | None = None, check: bool = True) -> subprocess.CompletedProcess:
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if check and r.returncode != 0:
        raise RuntimeError(f"{' '.join(cmd)}\n{r.stdout}\n{r.stderr}")
    return r


def apply_repo(repo: str, need: list[dict], state: dict, branch: str,
               train: str, dry: bool) -> str | None:
    """Clone, rewrite sibling revs, conventional-commit, push, open a PR."""
    tmp = tempfile.mkdtemp(prefix=f"prop-{repo}-")
    dest = os.path.join(tmp, repo)
    run(["git", "clone", "-q", "--depth", "50",
         f"https://github.com/{OWNER}/{repo}.git", dest])
    run(["git", "checkout", "-q", "-b", branch], cwd=dest)

    by_dep = {e["dep"]: e["to"] for e in need}
    changed_files, changed = [], 0
    for dirpath, dirnames, files in os.walk(dest):
        dirnames[:] = [d for d in dirnames if d not in (".git", "target")]
        if "Cargo.toml" not in files:
            continue
        p = os.path.join(dirpath, "Cargo.toml")
        txt = open(p, encoding="utf-8").read()

        def sub(m: re.Match) -> str:
            want = by_dep.get(m.group("repo"))
            return m.group("head") + want if want else m.group(0)

        new = RE_DEP.sub(sub, txt)
        if new != txt:
            open(p, "w", encoding="utf-8").write(new)
            changed_files.append(os.path.relpath(p, dest))
            changed += 1
    if not changed:
        return None

    lines = "\n".join(
        f"  {e['dep']}: {e['from'][:8]} -> {e['to'][:8]}" for e in sorted(need, key=lambda x: x["dep"]))
    body = f"""chore(deps): advance sibling pins to train {train}

Coordinated fleet propagation. Sibling components advanced on their default
branch; this repo's git `rev` pins still referenced the previous revisions, so
none of that work was visible here.

{lines}

Generated by scripts/fleet-propagate.py in tzervas/mycelium-lang. Only 40-char
`rev` values on tzervas/* git dependencies are rewritten — no version
requirements, features, or non-sibling dependencies are touched.
"""
    if dry:
        print(f"    [dry-run] would commit {changed} manifest(s) in {repo}")
        return None

    run(["git", "add", "-A"], cwd=dest)
    run(["git", "-c", "user.name=fleet-propagate",
         "-c", "user.email=noreply@github.com", "commit", "-q", "-m", body], cwd=dest)
    run(["git", "push", "-q", "-u", "origin", branch], cwd=dest)

    pr = {
        "title": f"chore(deps): advance sibling pins to train {train}",
        "head": branch, "base": "main", "body": body, "draft": False,
    }
    pf = os.path.join(tmp, "pr.json")
    json.dump(pr, open(pf, "w"))
    url = gh("--method", "POST", f"repos/{OWNER}/{repo}/pulls", "--input", pf, "--jq", ".html_url")
    return url or "(PR creation failed)"


# ---------------------------------------------------------------------- main

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["plan", "apply", "lock", "check"])
    ap.add_argument("--ref", default="main", help="branch to resolve targets from (default: main)")
    ap.add_argument("--only", default="", help="comma-separated repo subset")
    ap.add_argument("--wave", type=int, default=None, help="apply: which wave to open PRs for")
    ap.add_argument("--train", default="", help="train label used in commit/PR text")
    ap.add_argument("--branch", default="", help="branch name to create (default: chore/fleet-propagate)")
    ap.add_argument("--write", action="store_true", help="lock: write components.lock in place")
    ap.add_argument("--dry-run", action="store_true", help="apply: do everything except commit/push/PR")
    ap.add_argument("--state", default="", help="reuse a cached state json from a previous plan")
    args = ap.parse_args()

    _, pins = read_lock()
    repos = sorted(pins)
    if args.only:
        want = {x.strip() for x in args.only.split(",") if x.strip()}
        repos = [r for r in repos if r in want]

    if args.state and os.path.exists(args.state):
        state = json.load(open(args.state))
    else:
        print(f"resolving {len(repos)} repos at ref '{args.ref}' ...", file=sys.stderr)
        state = build_state(repos, args.ref)
        cache = args.state or os.path.join(tempfile.gettempdir(), "fleet-propagate-state.json")
        json.dump(state, open(cache, "w"))
        print(f"state cached -> {cache}", file=sys.stderr)

    train = args.train or "unspecified"
    wave, edits = compute_waves(state)

    if args.cmd == "check":
        return check_invariant(state)

    if args.cmd == "plan":
        rc = check_invariant(state)
        if rc:
            print("\nrefusing to plan against an inconsistent fleet — fix the "
                  "conflicts above first.", file=sys.stderr)
            return rc
        stale = [r for r in repos if pins[r]["rev"] != state[r]["target"]]
        print(f"\n=== LOCK PIN DRIFT (components.lock vs '{args.ref}') ===")
        print(f"pins total       : {len(repos)}")
        print(f"pins up to date  : {len(repos) - len(stale)}")
        print(f"pins STALE       : {len(stale)}")
        for r in stale:
            print(f"  {r:<26} {pins[r]['rev'][:8]} -> {state[r]['target'][:8]}")

        print(f"\n=== SIBLING DEP PROPAGATION WAVES ===")
        maxw = max(wave.values()) if wave else 0
        print(f"DAG depth / waves required: {maxw + 1} (wave 0 = no dependency edits needed)")
        for w in range(maxw + 1):
            members = sorted(r for r in repos if wave.get(r) == w and edits.get(r))
            if not members and w:
                continue
            print(f"\n-- wave {w}: {len(members)} repo(s) need Cargo.toml edits")
            for r in members:
                print(f"   {r}")
                for e in sorted(edits[r], key=lambda x: x["dep"]):
                    print(f"      {e['dep']:<26} {e['from'][:8]} -> {e['to'][:8]}")
        total = sum(len(v) for v in edits.values())
        print(f"\ntotal sibling rev edits: {total}")
        print(f"repos needing a PR     : {sum(1 for v in edits.values() if v)}")
        if maxw > 0:
            print(f"""
IMPORTANT — the target revs above are only exact for wave 1.

Merging a wave's PRs creates a new commit on each of those repos, so their HEADs
move. Every later wave must therefore be re-resolved against live state:

    for w in 1..{maxw}:
        python3 scripts/fleet-propagate.py plan          # fresh state, no --state
        python3 scripts/fleet-propagate.py apply --wave 1
        # merge that wave's PRs, then repeat

Always run `apply --wave 1` off a freshly resolved plan rather than replaying a
cached one — a cached state will pin revs that no longer exist as tips.""")
        return 0

    if args.cmd == "lock":
        lines, _ = read_lock()
        out, n = [], 0
        for ln in lines:
            m = RE_LOCK_PIN.match(ln)
            if not m or m.group("name") not in state:
                out.append(ln)
                continue
            name = m.group("name")
            rev = state[name]["target"]
            if rev == m.group("rev"):
                out.append(ln)
                continue
            tree = tree_of(name, rev) or m.group("tree") or ""
            out.append(f"{name}={rev}" + (f" tree={tree}" if tree else ""))
            n += 1
        text = "\n".join(out) + "\n"
        if args.write:
            open(LOCK, "w", encoding="utf-8").write(text)
            print(f"components.lock updated: {n} pin(s) advanced")
        else:
            sys.stdout.write(text)
            print(f"\n# {n} pin(s) would advance (use --write)", file=sys.stderr)
        return 0

    # apply
    if args.wave is None:
        print("error: apply requires --wave N (run 'plan' first)", file=sys.stderr)
        return 2
    branch = args.branch or "chore/fleet-propagate"
    members = sorted(r for r in repos if wave.get(r) == args.wave and edits.get(r))
    if not members:
        print(f"wave {args.wave}: nothing to do")
        return 0
    print(f"wave {args.wave}: {len(members)} repo(s)")
    for r in members:
        print(f"  -> {r}")
        try:
            url = apply_repo(r, edits[r], state, branch, train, args.dry_run)
            print(f"     {url or '(no change)'}")
        except (RuntimeError, OSError) as exc:
            print(f"     FAILED: {exc}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
