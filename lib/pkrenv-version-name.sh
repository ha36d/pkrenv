#!/usr/bin/env bash

set -uo pipefail;

function pkrenv-version-name() {
  if [[ -z "${PKRENV_PACKER_VERSION:-""}" ]]; then
    log 'debug' 'We are not hardcoded by a PKRENV_PACKER_VERSION environment variable';

    PKRENV_VERSION_FILE="$(pkrenv-version-file)" \
      && log 'debug' "PKRENV_VERSION_FILE retrieved from pkrenv-version-file: ${PKRENV_VERSION_FILE}" \
      || log 'error' 'Failed to retrieve PKRENV_VERSION_FILE from pkrenv-version-file';

    PKRENV_VERSION="$(cat "${PKRENV_VERSION_FILE}" || true)" \
      && log 'debug' "PKRENV_VERSION specified in PKRENV_VERSION_FILE: ${PKRENV_VERSION}";

    PKRENV_VERSION_SOURCE="${PKRENV_VERSION_FILE}";

  else
    PKRENV_VERSION="${PKRENV_PACKER_VERSION}" \
      && log 'debug' "PKRENV_VERSION specified in PKRENV_PACKER_VERSION environment variable: ${PKRENV_VERSION}";

    PKRENV_VERSION_SOURCE='PKRENV_PACKER_VERSION';
  fi;

  local auto_install="${PKRENV_AUTO_INSTALL:-true}";

  if [[ "${PKRENV_VERSION}" == "min-required" ]]; then
    log 'debug' 'PKRENV_VERSION uses min-required keyword, looking for a required_version in the code';

    local potential_min_required="$(pkrenv-min-required)";
    if [[ -n "${potential_min_required}" ]]; then
      log 'debug' "'min-required' converted to '${potential_min_required}'";
      PKRENV_VERSION="${potential_min_required}" \
      PKRENV_VERSION_SOURCE='packer{required_version}';
    else
      log 'error' 'Specifically asked for min-required via packer{required_version}, but none found';
    fi;
  fi;

  if [[ "${PKRENV_VERSION}" =~ ^latest.*$ ]]; then
    log 'debug' "PKRENV_VERSION uses 'latest' keyword: ${PKRENV_VERSION}";

    if [[ "${PKRENV_VERSION}" == latest-allowed ]]; then
        PKRENV_VERSION="$(pkrenv-resolve-version)";
        log 'debug' "Resolved latest-allowed to: ${PKRENV_VERSION}";
    fi;

    if [[ "${PKRENV_VERSION}" =~ ^latest\:.*$ ]]; then
      regex="${PKRENV_VERSION##*\:}";
      log 'debug' "'latest' keyword uses regex: ${regex}";
    else
      regex="^[0-9]\+\.[0-9]\+\.[0-9]\+$";
      log 'debug' "Version uses latest keyword alone. Forcing regex to match stable versions only: ${regex}";
    fi;

    declare local_version='';
    if [[ -d "${PKRENV_CONFIG_DIR}/versions" ]]; then
      local_version="$(\find "${PKRENV_CONFIG_DIR}/versions/" -type d -exec basename {} \; \
        | tail -n +2 \
        | sort -t'.' -k 1nr,1 -k 2nr,2 -k 3nr,3 \
        | grep -e "${regex}" \
        | head -n 1)";

      log 'debug' "Resolved ${PKRENV_VERSION} to locally installed version: ${local_version}";
    elif [[ "${auto_install}" != "true" ]]; then
      log 'error' 'No versions of packer installed and PKRENV_AUTO_INSTALL is not true. Please install a version of packer before it can be selected as latest';
    fi;

    if [[ "${auto_install}" == "true" ]]; then
      log 'debug' "Using latest keyword and auto_install means the current version is whatever is latest in the remote. Trying to find the remote version using the regex: ${regex}";
      remote_version="$(pkrenv-list-remote | grep -e "${regex}" | head -n 1)";
      if [[ -n "${remote_version}" ]]; then
          if [[ "${local_version}" != "${remote_version}" ]]; then
            log 'debug' "The installed version '${local_version}' does not much the remote version '${remote_version}'";
            PKRENV_VERSION="${remote_version}";
          else
            PKRENV_VERSION="${local_version}";
          fi;
      else
        log 'error' "No versions matching '${requested}' found in remote";
      fi;
    else
      if [[ -n "${local_version}" ]]; then
        PKRENV_VERSION="${local_version}";
      else
        log 'error' "No installed versions of packer matched '${PKRENV_VERSION}'";
      fi;
    fi;
  else
    log 'debug' 'PKRENV_VERSION does not use "latest" keyword';

    # Accept a v-prefixed version, but strip the v.
    if [[ "${PKRENV_VERSION}" =~ ^v.*$ ]]; then
      log 'debug' "Version Requested is prefixed with a v. Stripping the v.";
      PKRENV_VERSION="${PKRENV_VERSION#v*}";
    fi;
  fi;

  if [[ -z "${PKRENV_VERSION}" ]]; then
    log 'error' "Version could not be resolved (set by ${PKRENV_VERSION_SOURCE} or pkrenv use <version>)";
  fi;

  if [[ "${PKRENV_VERSION}" == min-required ]]; then
    PKRENV_VERSION="$(pkrenv-min-required)";
  fi;

  if [[ ! -d "${PKRENV_CONFIG_DIR}/versions/${PKRENV_VERSION}" ]]; then
    log 'debug' "version '${PKRENV_VERSION}' is not installed (set by ${PKRENV_VERSION_SOURCE})";
  fi;

  echo "${PKRENV_VERSION}";
};
export -f pkrenv-version-name;

