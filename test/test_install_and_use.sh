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
  [ "${PKRENV_DEBUG:-0}" -gt 0 ] && echo "[DEBUG] Sourcing helpers from ${PKRENV_ROOT}/lib/helpers.sh";
  if source "${PKRENV_ROOT}/lib/helpers.sh"; then
    log 'debug' 'Helpers sourced successfully';
  else
    early_death "Failed to source helpers from ${PKRENV_ROOT}/lib/helpers.sh";
  fi;
fi;

#####################
# Begin Script Body #
#####################

test_install_and_use() {
  # Takes a static version and the optional keyword to install it with
  local k="${2-""}";
  local v="${1}";
  pkrenv install "${k}" || return 1;
  check_installed_version "${v}" || return 1;
  pkrenv use "${k}" || return 1;
  check_active_version "${v}" || return 1;
  return 0;
};

test_install_and_use_with_env() {
  # Takes a static version and the optional keyword to install it with
  local k="${2-""}";
  local v="${1}";
  PKRENV_PACKER_VERSION="${k}" pkrenv install || return 1;
  check_installed_version "${v}" || return 1;
  PKRENV_PACKER_VERSION="${k}" pkrenv use || return 1;
  PKRENV_PACKER_VERSION="${k}" check_active_version "${v}" || return 1;
  return 0;
};

test_install_and_use_overridden() {
  # Takes a static version and the optional keyword to install it with
  local k="${2-""}";
  local v="${1}";
  pkrenv install "${k}" || return 1;
  check_installed_version "${v}" || return 1;
  pkrenv use "${k}" || return 1;
  check_default_version "${v}" || return 1;
  return 0;
};

declare -a errors=();

log 'info' '### Test Suite: Install and Use';

tests__desc=(
  'latest version'
  'latest possibly-unstable version'
  'latest alpha'
  'latest possibly-unstable version from 0.11'
  'latest version matching regex'
  'specific version'
  'specific version with v prefix'
);

tests__kv=(
  "$(pkrenv list-remote | grep -e "^[0-9]\+\.[0-9]\+\.[0-9]\+$" | head -n 1),latest"
  "$(pkrenv list-remote | head -n 1),latest:"
  "$(pkrenv list-remote | grep 'alpha' | head -n 1),latest:alpha"
  "$(pkrenv list-remote | grep '^0\.11\.' | head -n 1),latest:^0.11."
  '1.7.10,latest:^1.7'
  '1.7.9,1.7.9'
  '1.8.0,v1.8.0'
);

tests_count=${#tests__desc[@]};

declare desc kv k v test_num;

for ((test_iter=0; test_iter<${tests_count}; ++test_iter )) ; do
  cleanup || log 'error' 'Cleanup failed?!';
  test_num=$((test_iter + 1)); 
  desc=${tests__desc[${test_iter}]};
  kv="${tests__kv[${test_iter}]}";
  v="${kv%,*}";
  k="${kv##*,}";
  log 'info' "## Param Test ${test_num}/${tests_count}: ${desc} ( ${k} / ${v} )";
  test_install_and_use "${v}" "${k}" \
    && log info "## Param Test ${test_num}/${tests_count}: ${desc} ( ${k} / ${v} ) succeeded" \
    || error_and_proceed "## Param Test ${test_num}/${tests_count}: ${desc} ( ${k} / ${v} ) failed";
done;

for ((test_iter=0; test_iter<${tests_count}; ++test_iter )) ; do
  cleanup || log 'error' 'Cleanup failed?!';
  test_num=$((test_iter + 1)); 
  desc=${tests__desc[${test_iter}]};
  kv="${tests__kv[${test_iter}]}";
  v="${kv%,*}";
  k="${kv##*,}";
  log 'info' "## ./.packer-version Test ${test_num}/${tests_count}: ${desc} ( ${k} / ${v} )";
  log 'info' "Writing ${k} to ./.packer-version";
  echo "${k}" > ./.packer-version;
  test_install_and_use "${v}" \
    && log info "## ./.packer-version Test ${test_num}/${tests_count}: ${desc} ( ${k} / ${v} ) succeeded" \
    || error_and_proceed "## ./.packer-version Test ${test_num}/${tests_count}: ${desc} ( ${k} / ${v} ) failed";
done;

for ((test_iter=0; test_iter<${tests_count}; ++test_iter )) ; do
  cleanup || log 'error' 'Cleanup failed?!';
  test_num=$((test_iter + 1)); 
  desc=${tests__desc[${test_iter}]};
  kv="${tests__kv[${test_iter}]}";
  v="${kv%,*}";
  k="${kv##*,}";
  log 'info' "## PKRENV_PACKER_VERSION Test ${test_num}/${tests_count}: ${desc} ( ${k} / ${v} )";
  log 'info' "Writing 0.0.0 to ./.packer-version";
  echo "0.0.0" > ./.packer-version;
  test_install_and_use_with_env "${v}" "${k}" \
    && log info "## PKRENV_PACKER_VERSION Test ${test_num}/${tests_count}: ${desc} ( ${k} / ${v} ) succeeded" \
    || error_and_proceed "## PKRENV_PACKER_VERSION Test ${test_num}/${tests_count}: ${desc} ( ${k} / ${v} ) failed";
done;

cleanup || log 'error' 'Cleanup failed?!';
log 'info' '## ${HOME}/.packer-version Test Preparation';

# 0.12.22 reports itself as 0.12.21 and breaks testing
declare v1="$(pkrenv list-remote | grep -e "^[0-9]\+\.[0-9]\+\.[0-9]\+$" | grep -v '0.12.22' | head -n 2 | tail -n 1)";
declare v2="$(pkrenv list-remote | grep -e "^[0-9]\+\.[0-9]\+\.[0-9]\+$" | grep -v '0.12.22' | head -n 1)";

if [ -f "${HOME}/.packer-version" ]; then
  log 'info' "Backing up ${HOME}/.packer-version to ${HOME}/.packer-version.bup";
  mv "${HOME}/.packer-version" "${HOME}/.packer-version.bup";
fi;
log 'info' "Writing ${v1} to ${HOME}/.packer-version";
echo "${v1}" > "${HOME}/.packer-version";

log 'info' "## \${HOME}/.packer-version Test 1/3: Install and Use ( ${v1} )";
test_install_and_use "${v1}" \
  && log info "## \${HOME}/.packer-version Test 1/1: ( ${v1} ) succeeded" \
  || error_and_proceed "## \${HOME}/.packer-version Test 1/1: ( ${v1} ) failed";

log 'info' "## \${HOME}/.packer-version Test 2/3: Override Install with Parameter ( ${v2} )";
test_install_and_use_overridden "${v2}" "${v2}" \
  && log info "## \${HOME}/.packer-version Test 2/3: ( ${v2} ) succeeded" \
  || error_and_proceed "## \${HOME}/.packer-version Test 2/3: ( ${v2} ) failed";

log 'info' "## \${HOME}/.packer-version Test 3/3: Override Use with Parameter ( ${v2} )";
(
  pkrenv use "${v2}" || exit 1;
  check_default_version "${v2}" || exit 1;
) && log info "## \${HOME}/.packer-version Test 3/3: ( ${v2} ) succeeded" \
  || error_and_proceed "## \${HOME}/.packer-version Test 3/3: ( ${v2} ) failed";

log 'info' '## \${HOME}/.packer-version Test Cleanup';
log 'info' "Deleting ${HOME}/.packer-version";
rm "${HOME}/.packer-version";
if [ -f "${HOME}/.packer-version.bup" ]; then
  log 'info' "Restoring backup from ${HOME}/.packer-version.bup to ${HOME}/.packer-version";
  mv "${HOME}/.packer-version.bup" "${HOME}/.packer-version";
fi;

log 'info' '## Use Auto-Install Test 1/2: (No Input)';
cleanup || log 'error' 'Cleanup failed?!';

(
  pkrenv use || exit 1;
  check_default_version "$(pkrenv list-remote | grep -e "^[0-9]\+\.[0-9]\+\.[0-9]\+$" | head -n 1)" || exit 1;
) && log info '## Use Auto-Install Test 1/2: (No Input) succeeded' \
  || error_and_proceed '## Use Auto-Install Test 1/2: (No Input) failed';

log 'info' '## Use Auto-Install Test 2/2: (Specific version)';
cleanup || log 'error' 'Cleanup failed?!';

(
  pkrenv use 1.0.1 || exit 1;
  check_default_version 1.0.1 || exit 1;
) && log info '## Use Auto-Install Test 2/2: (Specific version) succeeded' \
  || error_and_proceed '## Use Auto-Install Test 2/2: (Specific version) failed';


log 'info' 'Install invalid specific version';
cleanup || log 'error' 'Cleanup failed?!';

neg_tests__desc=(
  'specific version'
  'latest:word'
);

neg_tests__kv=(
  '9.9.9'
  'latest:word'
);

neg_tests_count=${#neg_tests__desc[@]};

for ((test_iter=0; test_iter<${neg_tests_count}; ++test_iter )) ; do
  cleanup || log 'error' 'Cleanup failed?!';
  test_num=$((test_iter + 1));
  desc=${neg_tests__desc[${test_iter}]}
  k="${neg_tests__kv[${test_iter}]}";
  expected_error_message="No versions matching '${k}' found in remote";
  log 'info' "##  Invalid Version Test ${test_num}/${neg_tests_count}: ${desc} ( ${k} )";
  [ -z "$(pkrenv install "${k}" 2>&1 | grep "${expected_error_message}")" ] \
    && error_and_proceed "Installing invalid version ${k}";
done;

if [ "${#errors[@]}" -gt 0 ]; then
  log 'warn' '===== The following install_and_use tests failed =====';
  for error in "${errors[@]}"; do
    log 'warn' "\t${error}";
  done
  log 'error' 'Test failure(s): install_and_use';
else
  log 'info' 'All install_and_use tests passed';
fi;

exit 0;
