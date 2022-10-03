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
  if [ ! -z "$TARGETPLATFORM" ]; then
    echo "$RUST_DEFAULT_TARGET"
  elif [[ "$TARGETPLATFORM" == "linux/amd64" ]]; then
    echo "$RUST_TARGET_X86_64"
  elif [[ "$TARGETPLATFORM" == "linux/arm64" ]]; then
    echo "$RUST_TARGET_ARM64"
  else
    .error "unable to determine rust target for target platform ${TARGETPLATFORM}"
    return 1
  fi
}