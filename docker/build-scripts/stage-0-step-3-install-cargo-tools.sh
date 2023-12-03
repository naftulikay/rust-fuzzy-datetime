#!/usr/bin/env bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd )/lib/functions.sh"

CARGO_UTILITIES=("cargo-update")
CARGO_AUDIT_UTILITIES=("cargo-audit" "cargo-auditable" "rust-audit-info")

function .main() {
  .info "starting $0"

  local utilities
  utilities=("${CARGO_UTILITIES[@]}")

  if [[ "${RUST_RUN_AUDIT:-false}" == "true" ]] || [[ "${RUST_AUDITABLE_BINARY:-false}"  == "true" ]]; then
    .info "including audit utilities..."
    utilities+=("${CARGO_AUDIT_UTILITIES[@]}")
  else
    .info "not including audit utilities..."
  fi

  .debug "installing: $(echo -n "${utilities[@]}" | perl -p -e 's/\s+/, /g')"

  cargo install "${utilities[@]}"

  .info "completed $0"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  .main "$@"
fi