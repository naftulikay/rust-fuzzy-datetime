#!/usr/bin/env bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd )/lib/functions.sh"

function .main() {
  .info "starting $0"

  if [[ "${RUST_STRIP_BINARY:-false}" == "true" ]]; then
    .info "stripping binary as per RUST_STRIP_BINARY=${RUST_STRIP_BINARY}..."
    strip "target/$(.rustup_target)/release/${APP_BIN_NAME}"
  else
    .info "not stripping binary as per RUST_STRIP_BINARY=${RUST_STRIP_BINARY}..."
  fi

  .info "completed $0"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  .main "$@"
fi