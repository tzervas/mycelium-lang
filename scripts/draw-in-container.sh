#!/usr/bin/env bash
# Run umbrella-draw-in.sh inside a container image (Podman preferred, Docker fallback).
# Used for multi-distro / multi-arch emulation on the Linux fleet host.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:?IMAGE required e.g. ubuntu:24.04}"
PLATFORM="${PLATFORM:-}"          # e.g. linux/arm64
MODE="${MODE:-check}"
PIN_LIMIT="${PIN_LIMIT:-}"
RUST_PREINSTALLED="${RUST_PREINSTALLED:-0}"
DRAW_IN_OS="${DRAW_IN_OS:-container}"
DRAW_IN_ARCH="${DRAW_IN_ARCH:-x64}"

RUNTIME=()
if command -v podman >/dev/null 2>&1; then
  RUNTIME=(podman)
elif command -v docker >/dev/null 2>&1; then
  RUNTIME=(docker)
else
  echo "error: need podman or docker" >&2
  exit 2
fi

platform_args=()
if [[ -n "$PLATFORM" ]]; then
  platform_args=(--platform "$PLATFORM")
fi

# Bootstrap script inside the guest
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

echo "==> container draw-in image=$IMAGE platform=${PLATFORM:-host} mode=$MODE"
"${RUNTIME[@]}" run --rm \
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
