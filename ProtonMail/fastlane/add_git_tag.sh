#!/usr/bin/env bash

set -Eeuo pipefail

git_tag() {
    local tag=$1
    git remote set-url origin "https://${GIT_CI_USERNAME}:${PRIVATE_TOKEN_GITLAB_API_PROTON_CI}@$(awk -F '@' '{print $2}' <<< "$CI_REPOSITORY_URL")";
    git tag "$tag"
    git push origin "$tag"
}

PLIST_CMD="/usr/libexec/PlistBuddy"
PLIST="$CI_PROJECT_DIR/ProtonMail/ProtonMail/Supporting Files/Info.plist"
VERSION_NUMBER=$("$PLIST_CMD" -c "Print CFBundleShortVersionString" "$PLIST")
BUILD_NUMBER=$("$PLIST_CMD" -c "Print CFBundleVersion" "$PLIST")
GIT_TAG_NAME="${VERSION_NUMBER}/${BUILD_NUMBER}"

echo "Tagging with:"
echo $GIT_TAG_NAME

git_tag "$GIT_TAG_NAME"
