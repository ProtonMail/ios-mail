#!/bin/bash

# How to use
# sh xcodeGenHelper.sh

# If pod repo needs to be updated
# add flag --repo-update
# sh xcodeGenHelper.sh --repo-update

protonDirectory=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $protonDirectory

mint run xcodegen --spec project.json --project ./ --use-cache
if [ "$1" == "--repo-update" ]; then
    yes | pod install --repo-update
else
    yes | pod install
fi
