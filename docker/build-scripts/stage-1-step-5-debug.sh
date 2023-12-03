#!/usr/bin/env bash

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd )/lib/functions.sh"

function .main() {
  .info "starting $0"

  for filepath in "target/$(.rustup_target)/release/${APP_BIN_NAME}" \
      "target/$(.rustup_target)/release/examples/static-test" ; do
    .info "dumping metadata about ${filepath}..."
    .file_info "$filepath"
    .ldd "$filepath"
    .file_size "$filepath"
  done

  .info "completed $0"
}

function .ldd() {
  local file_path
  file_path="$1" && shift

  .info "ldd output for ${file_path}:"
  ldd "${file_path}" >&2
}

function .file_size() {
  local file_path
  file_path="$1" && shift

  .info "file size for ${file_path}:"
  du -bh "${file_path}" >&2
}

function .file_info() {
  local file_path
  file_path="$1" && shift

  .info "file info for ${file_path}:"
  file "${file_path}" >&2
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  .main "$@"
fi