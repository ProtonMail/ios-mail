#!/usr/bin/env bash

set -Eeuo pipefail
 
git_tag() {
    local tag=$1
    git remote set-url origin "https://${GIT_CI_USERNAME}:${PRIVATE_TOKEN_GITLAB_API_PROTON_CI}@$(awk -F '@' '{print $2}' <<< "$CI_REPOSITORY_URL")";
    git tag "$tag"
    git push origin "$tag"
}

PREFIX="v" 
BUILD_NUMBER="${CI_COMMIT_SHORT_SHA}"
VERSION_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$CI_PROJECT_DIR/ProtonMail/ProtonMail/Supporting Files/Info.plist")
GIT_TAG_NAME="${PREFIX}${VERSION_NUMBER}b${BUILD_NUMBER}"

echo "Tagging with:"
echo $GIT_TAG_NAME

git_tag "$GIT_TAG_NAME"