# Changelog

## [Unreleased]

### Added
- Progressive **OS/arch support matrix** (`docs/SUPPORT_MATRIX.md`, `.github/draw-in-matrix.json`).
- Required draw-in matrix: Linux host + Ubuntu 22.04/24.04 + Debian bookworm + Rocky 9 (Podman containers).
- Experimental: Fedora, arm64 QEMU, macOS/Windows GitHub-hosted smoke (non-blocking).
- `scripts/draw-in-container.sh` for distro/arch guests; release requires all **required** cells green.


### Added
- **Full pin draw-in** (`scripts/umbrella-draw-in.sh`): clone every Rust lock pin and run cargo check/test — user/developer install simulation.
- **CI** runs draw-in on PR (check), main/schedule (check+test).
- **Release** workflow runs draw-in at the exact rev before tagging (per-release polish gate).


