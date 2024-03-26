#!/bin/bash

set -euo pipefail

for link in $(grep -r "= \"https://" --include "*.swift" --exclude-dir={Pods,ProtonMailUITests,ProtonMailTests} ProtonMail | cut -d"\"" -f2); do
    echo "Checking $link..."
    curl --fail --output /dev/null --show-error --silent $link
done
