#!/bin/bash

set -eo pipefail

# This is to tell Xcode where to find Homebrew and therefore Mint.
# This is a very poor solution that
# 1. assumes Mint has been installed via Homebrew
# 2. assumes Homebrew has been installed to the default location
#
# Ideally we would just tell Xcode where to find the Mint executable.
# Note: Xcode has its own, sanitised PATH; the PATH you see below is not your user's PATH - that one most likely already includes the Homebrew directory.
if test -d "/opt/homebrew/bin/"; then
  PATH="/opt/homebrew/bin/:${PATH}"
fi

if test -d "/Users/proton/brew/bin/"; then
  PATH="/Users/proton/brew/bin/:${PATH}"
fi

if ! command -v mint >/dev/null; then
  echo "error: mint not found. Install it by executing \"brew install mint\" or if you already have it installed somewhere, ask the Mail team to update the script."
  exit 127
fi

REPOSITORY_ROOT="$(git rev-parse --show-toplevel)"
PATH_TO_MINTFILE="$REPOSITORY_ROOT/Mintfile"

if ! mint which "$1" --mintfile "$PATH_TO_MINTFILE" > /dev/null; then
  echo "error: Expected version of $1 not found. Install it by executing \"mint bootstrap\" in project root directory."
  exit 127
fi

mint run --mintfile "$PATH_TO_MINTFILE" "$@"
