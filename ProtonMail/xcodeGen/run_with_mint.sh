#!/bin/bash

set -eo pipefail

REPOSITORY_ROOT=$(git rev-parse --show-toplevel)
PATH_TO_MINTFILE="$REPOSITORY_ROOT/Mintfile"
MINT_CMD="xcrun --sdk macosx mint"

if ! $MINT_CMD which "$1" --mintfile $PATH_TO_MINTFILE > /dev/null; then
  echo "error: Expected version of $1 not found. Install it by executing \"mint bootstrap\" in project root directory."
  exit 65
fi

$MINT_CMD run --mintfile $PATH_TO_MINTFILE "$@"
