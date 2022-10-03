#!/usr/bin/env bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd )/lib/functions.sh"

function .main() {
  .info "starting $0"

  local rustup_target
  rustup_target="$(.rustup_target)"

  .info "building release binary with target ${rustup_target}..."

  # create symlink to make access easier
  ( cd target && ln -fs '../static' "$rustup_target" )

  .debug "link target/static points to $(readlink target/static)}"

  if [[ "${RUST_AUDITABLE_BINARY:-true}" == "true" ]]; then
    .info "including audit info in the binary..."
    cargo auditable build --target "$rustup_target" --release
  else
    .info "not including audit info in the binary..."
    cargo build --target "$rustup_target" --release
  fi

  .info "completed $0"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  .main "$@"
fi