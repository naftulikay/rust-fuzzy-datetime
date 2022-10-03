#!/usr/bin/env bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd )/lib/functions.sh"

function .main() {
  .info "starting $0"

  if [[ "${RUST_RUN_AUDIT:-true}" == "true" ]]; then
    .info "auditing dependencies via cargo audit..."
    cargo audit
  else
    .info "skipping audit step as per RUST_RUN_AUDIT=${RUST_RUN_AUDIT}"
  fi

  .info "completed $0"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  .main "$@"
fi