#!/usr/bin/env python3
"""Mechanical docs-gap survey across mycelium component repos."""
import os, re, sys, json, csv

ROOT = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("COMPONENTS_ROOT", ".")

RE_USAGE = re.compile(r'^#+ *(usage|getting started|quick ?start|example)', re.I | re.M)
RE_INSTALL = re.compile(r'^#+ *(install|installation)|\[dependencies\]', re.I | re.M)
RE_BADGE = re.compile(r'!\[[^\]]*\]\(https://(img\.shields\.io|github\.com/[^)]*badge)', re.I)
RE_PUB = re.compile(r'^[ \t]*pub (?:fn|struct|enum|trait|type|const|mod|union) ')
RE_DOC = re.compile(r'^[ \t]*///')
RE_ATTR = re.compile(r'^[ \t]*#\[')
RE_MISSING_DOCS = re.compile(r'^#!\[(?:warn|deny)\([^)]*missing_docs', re.M)


def read(p):
    try:
        with open(p, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return ""


def src_files(d):
    out = []
    for dirpath, dirnames, filenames in os.walk(d):
        dirnames[:] = [x for x in dirnames if x not in ("target", ".git")]
        if os.sep + "src" not in dirpath + os.sep:
            continue
        out += [os.path.join(dirpath, f) for f in filenames if f.endswith(".rs")]
    return out


def doc_coverage(files):
    """Count public items and how many are preceded by a /// doc comment."""
    pub = docd = 0
    for f in files:
        pending = False
        for line in read(f).splitlines():
            if RE_DOC.match(line):
                pending = True
                continue
            if RE_ATTR.match(line) or not line.strip():
                continue
            if RE_PUB.match(line):
                pub += 1
                if pending:
                    docd += 1
            pending = False
    return pub, docd


rows = []
for r in sorted(os.listdir(ROOT)):
    d = os.path.join(ROOT, r)
    if not os.path.isdir(d):
        continue

    readme = read(os.path.join(d, "README.md"))
    files = src_files(d)
    pub, docd = doc_coverage(files)

    # crate-level //! docs on the primary lib.rs
    lib = ""
    for cand in [os.path.join(d, "src", "lib.rs")] + [
        os.path.join(d, s, "src", "lib.rs") for s in os.listdir(d)
        if os.path.isdir(os.path.join(d, s))
    ]:
        if os.path.isfile(cand):
            lib = cand
            break
    libtxt = read(lib) if lib else ""

    docs_dir = os.path.join(d, "docs")
    docs_files = sum(
        len([f for f in fs if f.endswith(".md")])
        for _, _, fs in os.walk(docs_dir)
    ) if os.path.isdir(docs_dir) else 0

    wf = os.path.join(d, ".github", "workflows")
    workflows = sorted(f for f in os.listdir(wf)) if os.path.isdir(wf) else []

    rows.append({
        "repo": r,
        "readme_lines": len(readme.splitlines()),
        "usage": "yes" if RE_USAGE.search(readme) else "no",
        "install": "yes" if RE_INSTALL.search(readme) else "no",
        "badge": "yes" if RE_BADGE.search(readme) else "no",
        "CONTRIB": "yes" if os.path.isfile(os.path.join(d, "CONTRIBUTING.md")) else "no",
        "LICENSE": "yes" if any(x.startswith("LICENSE") for x in os.listdir(d)) else "no",
        "CHANGELOG": "yes" if os.path.isfile(os.path.join(d, "CHANGELOG.md")) else "no",
        "docs_md": docs_files,
        "cratedoc": len([l for l in libtxt.splitlines() if l.startswith("//!")]),
        "missing_docs_lint": "yes" if RE_MISSING_DOCS.search(libtxt) else "no",
        "examples": len([f for f in os.listdir(os.path.join(d, "examples"))
                         if f.endswith(".rs")]) if os.path.isdir(os.path.join(d, "examples")) else 0,
        "pub_items": pub,
        "doc_pub": docd,
        "doc_pct": round(100 * docd / pub) if pub else 0,
        "n_workflows": len(workflows),
        "has_release_wf": "yes" if any("release" in w for w in workflows) else "no",
    })

out = os.environ.get("SURVEY_JSON")
if out:
    with open(out, "w") as f:
        json.dump(rows, f, indent=1)

w = csv.DictWriter(sys.stdout, fieldnames=list(rows[0].keys()), delimiter="\t")
w.writeheader()
w.writerows(rows)
