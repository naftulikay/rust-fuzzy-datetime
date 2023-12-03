#!/usr/bin/env bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd )/lib/functions.sh"

function .main() {
  .info "starting $0"

  if [[ "${RUST_RUN_TESTS:-true}" == "true" ]]; then
    .info "running tests..."
    cargo test
  else
    .info "skipping tests as per RUST_RUN_TESTS=${RUST_RUN_TESTS}"
  fi

  .info "completed $0"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  .main "$@"
fi