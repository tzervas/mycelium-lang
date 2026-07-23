# Changelog

## [Unreleased]

### Fixed
- **Red `ci` on `main`:** re-pin `mycelium-fmt` to `948bb44` (tzervas/mycelium-fmt#5). Its conformance
  test resolved header fixtures through a monorepo-era sibling path
  (`$CARGO_MANIFEST_DIR/../mycelium-proj/tests/fixtures`), so it passed only where a sibling
  checkout happened to exist and could never pass a standalone component draw-in. The required
  `draw-in linux-x64-host` leg failed `ok=8 fail=1`, failing `required-gate`.
- **Honesty:** `components.lock` and `README.md` advertised all 45 pins as "tests green standalone".
  That was aspirational, not measured — the first full-scope sweep (all 45, `MODE=check+test`,
  `FAIL_FAST=0`) returned `ok=44 fail=1`. Both now record that the guarantee is measured, with the
  date and method, plus a note not to restate it for pins the gate has not exercised.
- Workflows: `actions/checkout@v5` (Node.js 24) to clear Node 20 deprecation warnings on fleet-security/trivy and other jobs.


### Added
- **Component-first** draw-in docs: each lock pin is a real `tzervas/*` repo; `component-draw-in.sh`, `COMPONENT_READINESS.md`, dual-mode `SHOWCASES.md`.
- Per-component JSONL report from umbrella draw-in (`REPORT_JSONL`).
- Progressive **OS/arch support matrix** (`docs/SUPPORT_MATRIX.md`, `.github/draw-in-matrix.json`).
- Required draw-in matrix: Linux host + Ubuntu 22.04/24.04 + Debian bookworm + Rocky 9 (Podman containers).
- Experimental: Fedora, arm64 QEMU, macOS/Windows GitHub-hosted smoke (non-blocking).
- `scripts/draw-in-container.sh` for distro/arch guests; release requires all **required** cells green.


### Added
- **Full pin draw-in** (`scripts/umbrella-draw-in.sh`): clone every Rust lock pin and run cargo check/test — user/developer install simulation.
- **CI** runs draw-in on PR (check), main/schedule (check+test).
- **Release** workflow runs draw-in at the exact rev before tagging (per-release polish gate).


