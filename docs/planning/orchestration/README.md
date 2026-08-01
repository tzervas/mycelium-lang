# Train orchestration (zipper)

**You are here:** planning packages that agents and workflows execute.

| Doc | Purpose |
|-----|---------|
| [ZIPPER.md](./ZIPPER.md) | Methodology — freeze seams, parallelize lanes |
| [AGENT-PIPELINE.md](./AGENT-PIPELINE.md) | Planner → implementers → adversarial → merge |
| [surfaces/](./surfaces/) | Frozen / pre-freeze API contracts |
| [packages/](./packages/) | Full work packages (JSON + MD) |
| [schemas/work-package.schema.json](./schemas/work-package.schema.json) | Package schema |

## Package board (critical path first)

| ID | WP | Status | Priority |
|----|-----|--------|----------|
| PKG-ORCH-WORKFLOWS | ORCH | ready | P0 |
| PKG-WP0-LOCK | WP-0 | implementing | P0 |
| PKG-WP4-TIER0 | WP-4 | zipping | P0 |
| PKG-WP1-FANOUT | WP-1/2 | ready | P1 |
| PKG-WP5-PROCESS-CODECS | WP-5 | blocked | P1 |
| PKG-WP6-NET | WP-6 | blocked | P1 |
| PKG-PORT-RUNNER | WP-7 | blocked | P1 |

Hub: https://github.com/tzervas/mycelium-lang/issues/30

## Kickoff order for agents/workflows

1. **PKG-ORCH-WORKFLOWS** (ap-workflows pins) — parallel with WP-0 finish
2. **PKG-WP0-LOCK** — merge PRs #27/#29
3. **PKG-WP4-TIER0** — zipper already landing; then L-RT → L-HOST → L-CLI
4. **PKG-WP1-FANOUT** — merge fan-outs + re-pin (can interleave after WP-0)
5. Codecs lane of WP-5 early (pure) once capacity
6. Rest of critical path as blockers clear

## Zipper rule

No implementer invents public wild names or workflow inputs. Amend `surfaces/` first.
