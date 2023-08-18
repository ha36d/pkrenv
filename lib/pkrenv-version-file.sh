#!/usr/bin/env bash

set -uo pipefail;

function find_local_version_file() {
  log 'debug' "Looking for a version file in ${1}";

  local root="${1}";

  while ! [[ "${root}" =~ ^//[^/]*$ ]]; do

    if [ -e "${root}/.packer-version" ]; then
      log 'debug' "Found at ${root}/.packer-version";
      echo "${root}/.packer-version";
      return 0;
    else
      log 'debug' "Not found at ${root}/.packer-version";
    fi;

    [ -n "${root}" ] || break;
    root="${root%/*}";

  done;

  log 'debug' "No version file found in ${1}";
  return 1;
};
export -f find_local_version_file;

function pkrenv-version-file() {
  if ! find_local_version_file "${PKRENV_DIR:-${PWD}}"; then
    if ! find_local_version_file "${HOME:-/}"; then
      log 'debug' "No version file found in search paths. Defaulting to PKRENV_CONFIG_DIR: ${PKRENV_CONFIG_DIR}/version";
      echo "${PKRENV_CONFIG_DIR}/version";
    fi;
  fi;
};
export -f pkrenv-version-file;
