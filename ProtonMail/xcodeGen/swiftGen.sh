#!/bin/bash

if test -d "/opt/homebrew/bin/"; then
  PATH="/opt/homebrew/bin/:${PATH}"
fi

export PATH

mint run  swiftgen config run --config "swiftgen/swiftgen.yml"
