#!/usr/bin/env bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd )/lib/functions.sh"

function .main() {
  .info "starting $0"
  .debug "system architecture is: $(uname -p)"
  .debug "target platform is: ${TARGETPLATFORM:-(unset)}"
  .debug "build platform is: ${BUILDPLATFORM:-(unset)}"
  .info "completed $0"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  .main "$@"
fi