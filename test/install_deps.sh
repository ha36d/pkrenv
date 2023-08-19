#!/usr/bin/env bash
set -uo pipefail;

if [[ $(uname) == 'Darwin' ]] && [ $(which brew) ]; then
  brew install grep;
fi;

if [[ "$(uname)" == *"MINGW64"* ]] || [[ "$(uname)" == *"MSYSNT"* ]] || [[ "$(uname)" == *"CYGWINNT"* ]] ; then
function rev() {
  (
    copy=$1
    len=${#copy}
    for((i=$len-1;i>=0;i--)); do rev="$rev${copy:$i:1}"; done
    echo $rev
  );
};
export -f rev;
fi;
