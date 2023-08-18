#!/usr/bin/env bash
set -uo pipefail;

echo "uname"
echo $(uname)
if [[ $(uname) == 'Darwin' ]] && [ $(which brew) ]; then
  brew install grep;
fi;
