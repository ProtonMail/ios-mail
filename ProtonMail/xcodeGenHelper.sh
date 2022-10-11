#!/bin/bash

protonDirectory="$(git rev-parse --show-toplevel)"/ProtonMail
cd $protonDirectory

# the version is specified here again to improve performance by skipping the resolution phase
xcodeGen/run_with_mint.sh xcodegen --spec project.json --project .

cp xcodeGen/IDETemplateMacros.plist ProtonMail.xcodeproj/xcshareddata/
