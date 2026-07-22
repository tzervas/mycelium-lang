# Changelog

## [Unreleased]

### Added
- **Full pin draw-in** (`scripts/umbrella-draw-in.sh`): clone every Rust lock pin and run cargo check/test — user/developer install simulation.
- **CI** runs draw-in on PR (check), main/schedule (check+test).
- **Release** workflow runs draw-in at the exact rev before tagging (per-release polish gate).


