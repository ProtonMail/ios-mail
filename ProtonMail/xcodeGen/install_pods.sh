#!/bin/bash

# yes is needed to go through SSH key fingerprint prompts on CI
if ! yes | pod install; then
    echo "pod install failed. It might be because the local repo is outdated - will refresh and retry once."
    pod cache clean --all --verbose
    rm -rfv ~/.cocoapods/repos/
    pod install --repo-update --verbose
fi
