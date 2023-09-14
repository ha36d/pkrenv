#!/usr/bin/env bash

set -uo pipefail;

####################################
# Ensure we can execute standalone #
####################################

function early_death() {
  echo "[FATAL] ${0}: ${1}" >&2;
  exit 1;
};

if [ -z "${PKRENV_ROOT:-""}" ]; then
  # http://stackoverflow.com/questions/1055671/how-can-i-get-the-behavior-of-gnus-readlink-f-on-a-mac
  readlink_f() {
    local target_file="${1}";
    local file_name;

    while [ "${target_file}" != "" ]; do
      cd "$(dirname ${target_file})" || early_death "Failed to 'cd \$(dirname ${target_file})' while trying to determine PKRENV_ROOT";
      file_name="$(basename "${target_file}")" || early_death "Failed to 'basename \"${target_file}\"' while trying to determine PKRENV_ROOT";
      target_file="$(readlink "${file_name}")";
    done;

    echo "$(pwd -P)/${file_name}";
  };

  PKRENV_ROOT="$(cd "$(dirname "$(readlink_f "${0}")")/.." && pwd)";
  [ -n ${PKRENV_ROOT} ] || early_death "Failed to 'cd \"\$(dirname \"\$(readlink_f \"${0}\")\")/..\" && pwd' while trying to determine PKRENV_ROOT";
else
  PKRENV_ROOT="${PKRENV_ROOT%/}";
fi;
export PKRENV_ROOT;

if [ -n "${PKRENV_HELPERS:-""}" ]; then
  log 'debug' 'PKRENV_HELPERS is set, not sourcing helpers again';
else
  [ "${PKRENV_DEBUG:-0}" -gt 0 ] && echo "[DEBUG] Sourcing helpers from ${PKRENV_ROOT}/lib/pkrev-helpers.sh";
  if source "${PKRENV_ROOT}/lib/pkrev-helpers.sh"; then
    log 'debug' 'Helpers sourced successfully';
  else
    early_death "Failed to source helpers from ${PKRENV_ROOT}/lib/pkrev-helpers.sh";
  fi;
fi;

#####################
# Begin Script Body #
#####################

declare -a errors=();

cleanup || log 'error' 'Cleanup failed?!';


log 'info' '### Install min-required normal version (#.#.#)';

minv='1.8.0';

echo "packer {
  required_version = \">=${minv}\"
}" > min_required.hcl;

(
  pkrenv install min-required;
  pkrenv use min-required;
  check_active_version "${minv}";
) || error_and_proceed 'Min required version does not match';

cleanup || log 'error' 'Cleanup failed?!';


log 'info' '### Install min-required incomplete version (#.#.<missing>)'

minv='1.8';

echo "packer {
  required_version = \">=${minv}\"
}" >> min_required.hcl;

(
  pkrenv install min-required;
  pkrenv use min-required;
  check_active_version "${minv}.0";
) || error_and_proceed 'Min required incomplete-version does not match';

cleanup || log 'error' 'Cleanup failed?!';


log 'info' '### Install min-required with PKRENV_AUTO_INSTALL';

minv='1.8.0';

echo "packer {
  required_version = \">=${minv}\"
}" >> min_required.hcl;
echo 'min-required' > .packer-version;

(
  PKRENV_AUTO_INSTALL=true packer version;
  check_active_version "${minv}";
) || error_and_proceed 'Min required auto-installed version does not match';

cleanup || log 'error' 'Cleanup failed?!';

if [ "${#errors[@]}" -gt 0 ]; then
  log 'warn' '===== The following use_minrequired tests failed =====';
  for error in "${errors[@]}"; do
    log 'warn' "\t${error}";
  done;
  log 'error' 'use_minrequired test failure(s)';
else
  log 'info' 'All use_minrequired tests passed.';
fi;

exit 0;
