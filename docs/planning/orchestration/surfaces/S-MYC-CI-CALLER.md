# S-MYC-CI-CALLER

**Owning repo:** `tzervas/ap-workflows`  
**Package:** `PKG-CI-TRUTH` (https://github.com/tzervas/mycelium-lang/issues/48)  
**Status:** proposed — NOT yet frozen

## Proposed signature

```rust
workflow_call target: .github/workflows/reusable-ci-mycelium.yml (already exists on `main`). Frozen caller shape every *-myc repo's .github/workflows/ci.yml installs in place of its `placeholder` job:
  jobs:
    ci:
      uses: tzervas/ap-workflows/.github/workflows/reusable-ci-mycelium.yml@v0.1
      with:
        project-dir: lib
        deny-warnings: true
        acknowledge-not-adopted: true
  on: push+pull_request branches:[dev] (adds PR trigger and `dev`; today these repos trigger only on `push:[main]`, so PRs are never gated at all).
CORRECTION to the package brief: the real input name is `project-dir`, not `project-root` — verified by reading the workflow source; do not invent an input.
```

## Rationale

Frozen once so all 45 repos get byte-identical callers via script, not 45 hand-authored variants. Job name stays `check` (the workflow's own comment: 'renaming it silently un-gates 46 repos'). Hard-blocked until ap-workflows PR #30 is merged to main AND image-runner-base's push-triggered rebuild has republished `ghcr.io/tzervas/ap-workflows/runner-base:latest` with the static myc-check baked in — verified via a green image-runner-base run on main, not assumed from the PR being mergeable.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
