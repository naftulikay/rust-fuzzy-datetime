#!/usr/bin/env bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd )/lib/functions.sh"

function .main() {
  .info "executing $0"

  (
    export DEBIAN_FRONTEND=noninteractive
    .info "updating the apt cache..."
    apt-get update
    .info "upgrading all system packages..."
    apt-get upgrade -y
    .info "installing required system packages..."
    apt-get install -y build-essential libssl-dev libcurl4-openssl-dev zlib1g-dev musl musl-dev musl-tools
    .info "ensuring ssl ca certificates are up to date..."
    /usr/sbin/update-ca-certificates

    .info "all system packages installed."
  )

  .info "completed $0"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  .main "$@"
fi