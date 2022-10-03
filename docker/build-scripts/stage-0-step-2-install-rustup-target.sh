#!/usr/bin/env bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd )/lib/functions.sh"

function .main() {
  .info "starting $0"
  local rustup_target
  rustup_target="$(.rustup_target)"

  .info "installing rustup target $rustup_target..."
  rustup target add "$rustup_target"
  rustup set default-host "$rustup_target"

  .info "completed $0"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  .main "$@"
fi