#!/bin/bash

set -euo pipefail

directory_to_search="$(git rev-parse --show-toplevel)"/ProtonMail

for link in $(grep -r "= \"https://" --include "*.swift" --exclude-dir={Pods,ProtonMailUITests,ProtonMailTests} "$directory_to_search" | cut -d"\"" -f2); do
    echo "Checking $link..."
    curl --fail --output /dev/null --show-error --silent $link
done
