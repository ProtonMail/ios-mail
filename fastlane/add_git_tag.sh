#!/bin/bash

BUILD_SETTINGS=$(xcodebuild -showBuildSettings)
VERSION_NUMBER=$(echo "$BUILD_SETTINGS" | grep MARKETING_VERSION | awk '{print $3}')
BUILD_NUMBER=$(echo "$BUILD_SETTINGS" | grep CURRENT_PROJECT_VERSION | awk '{print $3}')
GIT_TAG_NAME="v${VERSION_NUMBER}_${BUILD_NUMBER}"
echo $GIT_TAG_NAME

git remote set-url origin "https://${GIT_CI_USERNAME}:${TAGS_PUBLISHER_TOKEN}@$(awk -F '@' '{print $2}' <<< "$CI_REPOSITORY_URL")";
git tag $GIT_TAG_NAME
git push origin $GIT_TAG_NAME
