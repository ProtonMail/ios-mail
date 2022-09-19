#!/bin/bash

protonDirectory="$(git rev-parse --show-toplevel)"/ProtonMail
cd $protonDirectory

# the version is specified here again to improve performance by skipping the resolution phase
mint run xcodegen@2.32.0 --spec project.json --project .
