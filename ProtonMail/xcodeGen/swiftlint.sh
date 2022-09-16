#!/bin/bash

if test -d "/opt/homebrew/bin/"; then
  PATH="/opt/homebrew/bin/:${PATH}"
fi

export PATH

mint run swiftlint --config ${PROJECT_DIR}/swiftlint/swiftlint.yml
