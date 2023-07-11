#!/bin/bash

git submodule update --force

# Do not need the access to pod repo while generating the project file.
bundle exec pod install --no-repo-update
