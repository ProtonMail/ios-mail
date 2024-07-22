#!/bin/bash

VERSION_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Modules/App/Sources/Info.plist)
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" Modules/App/Sources/Info.plist)
GIT_TAG_NAME="v${VERSION_NUMBER}_${BUILD_NUMBER}"
echo $GIT_TAG_NAME

git remote set-url origin "https://${GIT_CI_USERNAME}:${PRIVATE_TOKEN_GITLAB_API_PROTON_CI}@$(awk -F '@' '{print $2}' <<< "$CI_REPOSITORY_URL")";
git tag $GIT_TAG_NAME
git push origin $GIT_TAG_NAME
