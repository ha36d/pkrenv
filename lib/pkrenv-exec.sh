#!/usr/bin/env bash

set -uo pipefail;

function pkrenv-exec() {
  for _arg in ${@:1}; do
    if [[ "${_arg}" == -chdir=* ]]; then
      log 'debug' "Found -chdir arg. Setting PKRENV_DIR to: ${_arg#-chdir=}";
      export PKRENV_DIR="${PWD}/${_arg#-chdir=}";
    fi;
  done;

  log 'debug' 'Getting version from pkrenv-version-name';
  PKRENV_VERSION="$(pkrenv-version-name)" \
    && log 'debug' "PKRENV_VERSION is ${PKRENV_VERSION}" \
    || {
      # Errors will be logged from pkrenv-version name,
      # we don't need to trouble STDERR with repeat information here
      log 'debug' 'Failed to get version from pkrenv-version-name';
      return 1;
    };
  export PKRENV_VERSION;

  if [ ! -d "${PKRENV_CONFIG_DIR}/versions/${PKRENV_VERSION}" ]; then
  if [ "${PKRENV_AUTO_INSTALL:-true}" == "true" ]; then
    if [ -z "${PKRENV_PACKER_VERSION:-""}" ]; then
      PKRENV_VERSION_SOURCE="$(pkrenv-version-file)";
    else
      PKRENV_VERSION_SOURCE='PKRENV_PACKER_VERSION';
    fi;
      log 'info' "version '${PKRENV_VERSION}' is not installed (set by ${PKRENV_VERSION_SOURCE}). Installing now as PKRENV_AUTO_INSTALL==true";
      pkrenv-install;
    else
      log 'error' "version '${PKRENV_VERSION}' was requested, but not installed and PKRENV_AUTO_INSTALL is not 'true'";
    fi;
  fi;

  TF_BIN_PATH="${PKRENV_CONFIG_DIR}/versions/${PKRENV_VERSION}/packer";
  export PATH="${TF_BIN_PATH}:${PATH}";
  log 'debug' "TF_BIN_PATH added to PATH: ${TF_BIN_PATH}";
  log 'debug' "Executing: ${TF_BIN_PATH} $@";

  exec "${TF_BIN_PATH}" "$@" \
  || log 'error' "Failed to execute: ${TF_BIN_PATH} $*";

  return 0;
};
export -f pkrenv-exec;
