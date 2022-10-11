#!/bin/bash

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
export PATH

# If `mint run` is executed in a directory other than the one with the Mintfile, it will attempt to install the latest available version of the package, regardless of the version installed with `mint bootstrap`.
# Therefore we need to always point Mint to the Mintfile to make it deterministic.
# SRCROOT is not set when this script is run from outside of Xcode.
if test -z "$SRCROOT"; then
  REPOSITORY_ROOT=$(git rev-parse --show-toplevel)
  PATH_TO_MINTFILE="$REPOSITORY_ROOT/Mintfile"
else
  PATH_TO_MINTFILE="$SRCROOT/../Mintfile"
fi

mint run --mintfile $PATH_TO_MINTFILE "$@"
