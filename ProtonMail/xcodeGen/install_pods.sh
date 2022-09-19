#!/bin/bash

# yes is needed to go through SSH key fingerprint prompts on CI
if ! yes | pod install; then
    # if `pod install` failed, it was probably because of outdated local repo
    # try once more, this time updating it
    yes| pod install --repo-update
fi
