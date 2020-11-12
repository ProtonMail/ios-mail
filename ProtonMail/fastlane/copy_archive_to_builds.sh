#!/bin/bash

# Usage
# 
# Copy $XCODEBUILD_ARCHIVE to builds folder
# ./copy.sh

cd ..
cp -R "$XCODEBUILD_ARCHIVE" "outputs/"
zip -r "archive.zip" "outputs/"
cd fastlane