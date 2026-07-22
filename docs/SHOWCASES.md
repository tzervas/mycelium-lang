# Realistic dual-mode showcases (component-backed)

Goal: show Mycelium’s **native** strengths with **two honest modes** up front —
not toy demos, not vapor.

| Mode | Name | Promise |
|------|------|---------|
| **Fast / loose** | `fast` | Memory-safe, ergonomic, low ceremony; provenance optional/light |
| **Hardcore certified** | `certified` | Traceable, auditable, transparent EXPLAIN, guarantee tags, content-addressed artifacts |

Both modes must run against **real component repos** at locked revs (draw-in), not
only monorepo in-tree paths.

## Showcase A — Dense linear algebra kernel (ML base)

**Components:** `mycelium-std-dense`, `mycelium-std-math`, `mycelium-std-numerics`,
`mycelium-std-rand`, `mycelium-runtime`

| | Fast | Certified |
|--|------|-----------|
| **Story** | Matmul / batch norm style op for training loops | Same op with full guarantee lattice + EXPLAIN of every bound |
| **UX** | One-liner invoke, default `fast` | Explicit `certified` flag; refuses silent approx |
| **Artifact** | Optional spore | Content-addressed spore + guarantee matrix attachment |
| **Success** | Throughput-oriented bench green | Differential: certified ≡ fast values; EXPLAIN non-empty |

## Showcase B — VSA / ternary memory sketch (AI memory)

**Components:** `mycelium-std-vsa`, `mycelium-std-ternary`, `mycelium-std-content`,
`mycelium-std-spore`

| | Fast | Certified |
|--|------|-----------|
| **Story** | Bind/bundle/query for agent memory scratchpad | Same with provenance of every bind and never-silent gap |
| **UX** | Interactive REPL-ish CLI | Audit log + citation hooks (tero-shaped) |
| **Success** | Latency for retrieve | Reconstructable history; no silent drop |

## Showcase C — “Install the train” developer path

**Components:** **all 45 lock pins** via umbrella draw-in

| | Fast | Certified |
|--|------|-----------|
| **Story** | `MODE=check` multi-OS smoke | `MODE=check+test` required OS matrix before release |
| **UX** | `bash scripts/umbrella-draw-in.sh` | release.yml required matrix |
| **Success** | All components build on Ubuntu/Debian/Rocky/host | All required cells green + report JSONL |

## Showcase D — Transpile gap profile (honesty instrument)

**Components:** `mycelium-transpile` + targets e.g. `mycelium-std-collections`

| | Fast | Certified |
|--|------|-----------|
| **Story** | Emit drafts + gap % for a crate | Never-silent gap report as release artifact; no fake “100%” |
| **Success** | `checked_fraction` measured | Report + DN-111 classification of residuals |

## Python AI/ML corpus → native Mycelium (later track)

Prioritize **problems**, not line-for-line CPython ports (DN-111). Starter
corpus (problem → native component home):

| Use problem | Typical Python | Native Mycelium home (fast + certified variants) |
|-------------|----------------|--------------------------------------------------|
| Dense linear algebra | numpy | `std-dense` / `std-numerics` |
| Autodiff / training loop shape | torch (subset) | runtime + dense (idiomatic, not full torch) |
| Token / text | transformers tokenizers | `std-text` + content |
| Embeddings / associative memory | custom / FAISS-like | `std-vsa` |
| RNG | numpy.random | `std-rand` |
| Metrics / logging | logging | `std-diag` + EXPLAIN |
| Serialization | pickle/json | spores + content-addressing |
| HTTP datasets | requests | `std-io` / host effects (Interop Bridge early) |

Each library showcase should ship:

1. **fast** example program (component or monorepo `examples/`)
2. **certified** twin with guarantee tags + EXPLAIN dump
3. Draw-in row green for underlying components on required OS matrix

## Implementation order

1. Keep component draw-in + multi-OS matrix green (this umbrella).
2. Land Showcase C artifacts (JSONL reports in CI).
3. Showcase A/B as monorepo examples consuming component pins.
4. Showcase D as release-adjacent honesty for transpile readiness.
5. Python corpus RFCs only after language residual list (DN inventory) is owned.
