#!/usr/bin/env bash
# Resolve one distro/arch draw-in cell, on nested OR bare containerisation.
#
# WHY THIS IS NOT JUST `podman run`
# The fleet runners are themselves rootless-podman containers spawned by
# tzervas/gha-runner-ctl, and they carry no in-container engine. A script that
# unconditionally shells out to `podman run` therefore cannot work there — which
# is exactly why every container-mode cell was permanently red. This resolves
# four ways instead of assuming one:
#
#   1. NESTED     a working engine is present -> run the requested image.
#                 Full image fidelity. This is the only mode that tests the image.
#   2. EQUIVALENT no engine, and the host already IS this distro/arch, and the
#                 native host cell already covers it -> report covered, do not
#                 re-run. Keeps weekly load sane instead of duplicating a
#                 whole 45-pin draw-in for identical coverage.
#   3. BARE       no engine, host IS this distro/arch, but dedupe is off ->
#                 run the draw-in in place. Real distro coverage, no nesting.
#   4. REFUSE     no engine and the host is a different distro/arch. There is no
#                 honest way to test Fedora on Ubuntu without an engine, so emit
#                 a typed refusal and exit 0 — neutral, not a fake pass, and not
#                 a red failure that carries no information.
#
# Case 4 never runs a gate and never claims to. `STRICT_CONTAINER=1` turns it
# into a hard failure for callers that require genuine nesting.
#
# Env:
#   DEDUPE_HOST_EQUIVALENT  1 (default) = case 2, 0 = force case 3
#   STRICT_CONTAINER        1 = case 4 fails instead of skipping
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:?IMAGE required e.g. ubuntu:24.04}"
PLATFORM="${PLATFORM:-}"          # e.g. linux/arm64
MODE="${MODE:-check}"
PIN_LIMIT="${PIN_LIMIT:-}"
RUST_PREINSTALLED="${RUST_PREINSTALLED:-0}"
DRAW_IN_OS="${DRAW_IN_OS:-container}"
DRAW_IN_ARCH="${DRAW_IN_ARCH:-x64}"
STRICT_CONTAINER="${STRICT_CONTAINER:-0}"
DEDUPE_HOST_EQUIVALENT="${DEDUPE_HOST_EQUIVALENT:-1}"

# ---------------------------------------------------------------- host identity

# Normalise /etc/os-release into the same vocabulary the matrix uses for
# DRAW_IN_OS (ubuntu-24.04, debian-bookworm, rocky-9, fedora, ...).
host_os_id() {
  [ -r /etc/os-release ] || { echo unknown; return; }
  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-unknown}" in
    ubuntu) echo "ubuntu-${VERSION_ID:-unknown}" ;;
    debian) echo "debian-${VERSION_CODENAME:-unknown}" ;;
    rocky | rhel | almalinux) echo "rocky-${VERSION_ID%%.*}" ;;
    fedora) echo "fedora" ;;
    alpine) echo "alpine" ;;
    *) echo "${ID:-unknown}" ;;
  esac
}

host_arch_id() {
  case "$(uname -m)" in
    x86_64 | amd64) echo x64 ;;
    aarch64 | arm64) echo arm64 ;;
    riscv64) echo riscv64 ;;
    *) uname -m ;;
  esac
}

# A usable engine is one that can actually create containers, not merely a binary
# on PATH. Inside an engine-less runner `podman` may exist and still fail, so
# probe `info` rather than trusting `command -v`.
detect_engine() {
  local e
  for e in podman docker; do
    if command -v "$e" >/dev/null 2>&1 && "$e" info >/dev/null 2>&1; then
      echo "$e"
      return 0
    fi
  done
  return 1
}

HOST_OS="$(host_os_id)"
HOST_ARCH="$(host_arch_id)"
ENGINE="$(detect_engine || true)"

echo "==> draw-in cell: os=${DRAW_IN_OS} arch=${DRAW_IN_ARCH} image=${IMAGE} platform=${PLATFORM:-host} mode=${MODE}"
echo "    host: os=${HOST_OS} arch=${HOST_ARCH} nested-engine=${ENGINE:-none}"

# ------------------------------------------------------------------ 1. NESTED

if [ -n "${ENGINE}" ]; then
  echo "    resolution: NESTED via ${ENGINE} (image is genuinely under test)"
  platform_args=()
  [ -n "$PLATFORM" ] && platform_args=(--platform "$PLATFORM")

  read -r -d '' GUEST <<'GUEST' || true
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
if [ "${RUST_PREINSTALLED}" != "1" ]; then
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y -qq curl ca-certificates git build-essential pkg-config libssl-dev >/dev/null
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y -q curl ca-certificates git gcc gcc-c++ make pkgconf-pkg-config openssl-devel >/dev/null
  elif command -v microdnf >/dev/null 2>&1; then
    microdnf install -y curl ca-certificates git gcc gcc-c++ make pkgconfig openssl-devel >/dev/null
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache curl ca-certificates git build-base pkgconf openssl-dev >/dev/null
  fi
  if ! command -v cargo >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
  fi
fi
export PATH="$HOME/.cargo/bin:/usr/local/cargo/bin:$PATH"
cd /work
export MODE PIN_LIMIT DRAW_IN_OS DRAW_IN_ARCH WORKDIR=/tmp/drawin
bash scripts/umbrella-draw-in.sh
GUEST

  exec "${ENGINE}" run --rm \
    "${platform_args[@]}" \
    -e MODE="$MODE" \
    -e PIN_LIMIT="$PIN_LIMIT" \
    -e RUST_PREINSTALLED="$RUST_PREINSTALLED" \
    -e DRAW_IN_OS="$DRAW_IN_OS" \
    -e DRAW_IN_ARCH="$DRAW_IN_ARCH" \
    -v "$ROOT:/work:ro" \
    -w /work \
    "$IMAGE" \
    bash -lc "$GUEST"
fi

# ------------------------------------------- 2/3. host already is this target
#
# Arch must match exactly: with no engine there is no QEMU shim, so an arm64 cell
# cannot be honestly satisfied on an x64 host.

if [ "${DRAW_IN_ARCH}" = "${HOST_ARCH}" ] && [ "${DRAW_IN_OS}" = "${HOST_OS}" ]; then
  if [ "${DEDUPE_HOST_EQUIVALENT}" = "1" ]; then
    echo "    resolution: EQUIVALENT — host is ${HOST_OS}/${HOST_ARCH}, already covered"
    echo "::notice title=cell covered by the native host gate::${DRAW_IN_OS}/${DRAW_IN_ARCH} is the fleet host's own distro, so the required native draw-in already exercises it. Skipping a duplicate 45-pin run. Set DEDUPE_HOST_EQUIVALENT=0 to run it anyway."
    cat >&2 <<EOF
Covered: ${DRAW_IN_OS}/${DRAW_IN_ARCH} equals the host, and the native host cell
already runs the full draw-in there. Re-running would duplicate identical
coverage for a second full pass over all pins.

Note honestly what this does and does not mean: the DISTRO is covered, the
container IMAGE is not (no engine here to run it). Only NESTED mode tests the
image itself.
EOF
    exit 0
  fi

  echo "    resolution: BARE — host is ${HOST_OS}/${HOST_ARCH}, running in place"
  if ! command -v cargo >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    { [ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"; } || true
  fi
  if ! command -v cargo >/dev/null 2>&1; then
    echo "::error::BARE draw-in needs cargo on the runner and it is absent." >&2
    echo "::error::Refusing rather than reporting a pass for a cell that never built." >&2
    exit 2
  fi
  export MODE PIN_LIMIT DRAW_IN_OS DRAW_IN_ARCH
  export WORKDIR="${WORKDIR:-/tmp/drawin-bare}"
  cd "$ROOT"
  exec bash scripts/umbrella-draw-in.sh
fi

# ------------------------------------------------------------------ 4. REFUSE

reason="no nested container engine on this runner"
[ "${DRAW_IN_ARCH}" != "${HOST_ARCH}" ] &&
  reason="${reason}; arch ${DRAW_IN_ARCH} != host ${HOST_ARCH} and emulation needs an engine"
[ "${DRAW_IN_OS}" != "${HOST_OS}" ] &&
  reason="${reason}; distro ${DRAW_IN_OS} != host ${HOST_OS}"

echo "::notice title=draw-in cell unsupported on this runner::${DRAW_IN_OS}/${DRAW_IN_ARCH}: ${reason}"
cat >&2 <<EOF
Unsupported: cell ${DRAW_IN_OS}/${DRAW_IN_ARCH} cannot be provided on this runner.
  ${reason}

This is a typed refusal, not a pass: no gate ran and none is claimed.
To satisfy this cell for real, either
  - register a ${DRAW_IN_OS} distro-image runner in the fleet so it resolves BARE, or
  - give this runner a working nested engine so it resolves NESTED.
Set STRICT_CONTAINER=1 to make this a hard failure instead of a neutral skip.
EOF

if [ "${STRICT_CONTAINER}" = "1" ]; then
  echo "::error::STRICT_CONTAINER=1 and this cell is unsupported here" >&2
  exit 2
fi
exit 0
