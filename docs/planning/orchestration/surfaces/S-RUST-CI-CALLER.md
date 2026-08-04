# S-RUST-CI-CALLER

**Owning repo:** `tzervas/ap-workflows`  
**Package:** `PKG-CI-TRUTH` (https://github.com/tzervas/mycelium-lang/issues/48)  
**Status:** proposed — NOT yet frozen

## Proposed signature

```rust
workflow_call target: .github/workflows/reusable-ci-rust.yml (already exists and stable — no change needed to the reusable itself). Frozen caller shape for each of the 49 real component repos (all currently: name:ci, job:check, runs-on:ubuntu-latest, cargo fmt/clippy -D warnings/test, triggers push+pull_request:[main] only):
  jobs:
    ci:
      uses: tzervas/ap-workflows/.github/workflows/reusable-ci-rust.yml@v0.1
      with:
        depth: check+test
        deny-warnings: true
        runner-labels: '["self-hosted","linux","x64","podman"]'
        ecosystem-lock-ref: <mycelium-lang ref pinned per components.lock>
  on: push+pull_request branches:[dev] (moves off github-hosted ubuntu-latest onto the self-hosted rootless fleet per ZIPPER.md, and off main-only triggering).
Repos with a pre-existing repo-specific step (e.g. mycelium-cli's `cargo test --features net-host`) carry it forward via `setup-command`/a follow-on step, never silently dropped.
```

## Rationale

Job name `check` is the required context reusable-ci-rust.yml's own header names as load-bearing ('Renaming it silently un-gates 46 repos'). ecosystem-lock-ref/dep-overrides already exist on the reusable per the 2026-08-01 materializer adopt-now decision, so this is composition, not new design.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
