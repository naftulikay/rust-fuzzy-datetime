#!/usr/bin/env bash

RUST_TARGET_X86_64=x86_64-unknown-linux-musl
RUST_TARGET_ARM64=aarch64-unknown-linux-musl
RUST_DEFAULT_TARGET="$RUST_TARGET_X86_64"

function .log() {
  echo "*** $*" >&2
}

function .debug() {
  .log "[debug] $*"
}

function .info() {
  .log "[info ] $*"
}

function .warn() {
  .log "[warn ] $*"
}

function .error() {
  .log "[error] $*"
}

function .fail() {
  local message
  message="$1" && shift

  local code
  code="${1:-1}" && shift

  .log "[fatal] $message" && exit "$code"
}

function .rustup_target() {
  if [[ -z "${TARGETPLATFORM:-}" ]]; then
    .warn "TARGETPLATFORM is not defined, attempting to detect architecture manually..."

    local dpkg_architecture
    dpkg_architecture="$(dpkg --print-architecture)"

    if [[ "$dpkg_architecture" == "amd64" ]]; then
      TARGETPLATFORM="linux/amd64"
    elif [[ "$dpkg_architecture" == "arm64" || "$dpkg_architecture" == "aarch64" ]]; then
      TARGETPLATFORM="linux/arm64"
    else
      .fail "unable to detect a recognized architecture: ${dpkg_architecture}"
    fi
  fi

  if [[ "$TARGETPLATFORM" == "linux/amd64" ]]; then
    echo "$RUST_TARGET_X86_64"
  elif [[ "$TARGETPLATFORM" == "linux/arm64" ]]; then
    echo "$RUST_TARGET_ARM64"
  else
    .fail "unable to determine rust target for target platform ${TARGETPLATFORM}"
  fi
}