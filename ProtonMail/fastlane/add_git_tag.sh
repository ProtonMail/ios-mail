#!/usr/bin/env bash

set -Eeuo pipefail
 
git_tag() {
    local tag=$1
    git remote set-url origin "https://${GIT_CI_USERNAME}:${PRIVATE_TOKEN_GITLAB_API_PROTON_CI}@$(awk -F '@' '{print $2}' <<< "$CI_REPOSITORY_URL")";
    git tag "$tag"
    git push origin "$tag"
}

generate_tag_name() {
    local prefix="v" 
    local build_number="${ci_commit_short_sha}"
    local version_number=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$CI_PROJECT_DIR/ProtonMail/ProtonMail/Supporting Files/Info.plist")
    local git_tag_name="${prefix}${version_number}b${build_number}"
    return $git_tag_name
}

generate_tag_name
GIT_TAG_NAME=$?

echo "Tagging with: ${GIT_TAG_NAME}"
git_tag "$GIT_TAG_NAME"