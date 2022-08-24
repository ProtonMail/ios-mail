#!/bin/bash

# Usage
#
# Release new version to GitHub
#
# sh release.sh TAG_VERSION VERSION, sh release.sh v1.0.0 1.0.0
# sh release.sh BRANCH VERSION, sh release.sh release/1.0.0 1.0.0

# Configuration to abort the script when a command fails.
set -e

green_echo(){
    GREEN="\033[0;32m"
    NO_COLOR="\033[0m"
    printf "${GREEN}${1} ${NO_COLOR}\n"
}

red_echo(){
    RED="\033[0;31m"
    NO_COLOR="\033[0m"
    printf "${RED}${1} ${NO_COLOR}\n"
}

delete_branch(){
    # we allow errors inside the function because the branch maybe does not exist
    set +e
    git branch -D $1
    set -e
}

# Checkout a branch making sure it is up to date
checkout_updated_branch(){
    delete_branch $1
    git checkout $1
}

# Variables

PROJECT_FILE="ProtonMail/ProtonMail.xcodeproj/project.pbxproj"

SOURCE=$1
VERSION=$2
if [[ -z "$SOURCE" || -z "$VERSION" ]]; then
    echo "Please provide a source and a version"
    echo "e.g. 'sh "$0" v4.0.1 4.0.1' or 'sh "$0" release/4.0.1 4.0.1'"
    exit 1
fi

# Checking env variables exist
if [[ -z "$DEV_TEAM_ID_1" || -z "$DEV_TEAM_ID_2" ]]; then
    red_echo "Environement variables for development team ID not found, please declare them by follwing the documentation"
    echo "More info: https://confluence.protontech.ch/pages/viewpage.action?spaceKey=MIOS&title=Prepare+the+app+to+be+published+to+GitHub"
    exit 1
fi

echo "Creating a new commit for '$SOURCE' changes in branch 'staging'..."

green_echo "⌘ git prune and fetch"
# Prune local branches and fetch data from origin.
git fetch -p

green_echo "⌘ Checkout to updated branch '$SOURCE'"
checkout_updated_branch "$SOURCE"

green_echo "⌘ Checkout to updated branch 'staging'"
checkout_updated_branch "staging"

green_echo "⌘ Create a new branch 'stage/$VERSION'"
delete_branch "stage/$VERSION"
git checkout -b "stage/$VERSION"

green_echo "⌘ Bringing changes from branch '$SOURCE' (it could take some time)..."
yes | git checkout $SOURCE -p &>/dev/null

# because the previous git command won't bring changes in binaries we do it manually
green_echo "⌘ Bringing binaries from '$SOURCE'"
find . -type f \( -name '*.png' -o -name '*.pdf' \) -delete
git checkout "$SOURCE" -- "*.png" "*.pdf"


green_echo "⌘ Remove development team ids from '$PROJECT_FILE'"

sed -i '' 's/'$DEV_TEAM_ID_1'/""/g' "$PROJECT_FILE"
sed -i '' 's/'$DEV_TEAM_ID_2'/""/g' "$PROJECT_FILE"

if grep -q -i "$DEV_TEAM_ID_1\|$DEV_TEAM_ID_2"  "$PROJECT_FILE"; then
    red_echo "error: development team ID can still be found in '$PROJECT_FILE'"
    exit 1
else
    echo "development team ID removed"
fi

green_echo "⌘ Remove references to provisioning profiles from '$PROJECT_FILE'"

sed -i '' 's/ProtonMail Siri kit dev//g' "$PROJECT_FILE"
sed -i '' 's/Protonmail Siri kit release//g' "$PROJECT_FILE"
sed -i '' 's/development siriDev//g' "$PROJECT_FILE"
sed -i '' 's/production siriDev//g' "$PROJECT_FILE"

sed -i '' 's/protonmail push development//g' "$PROJECT_FILE"
sed -i '' 's/protonmail push dev//g' "$PROJECT_FILE"
sed -i '' 's/protonmail push release//g' "$PROJECT_FILE"
sed -i '' 's/protonmail push Production//g' "$PROJECT_FILE"

sed -i '' 's/protonmail push service Production//g' "$PROJECT_FILE"
sed -i '' 's/protonmail push service release//g' "$PROJECT_FILE"
sed -i '' 's/protonmail push service development//g' "$PROJECT_FILE"
sed -i '' 's/protonmail push service dev//g' "$PROJECT_FILE"

sed -i '' 's/Protonmail share release//g' "$PROJECT_FILE"
sed -i '' 's/protonmail share development//g' "$PROJECT_FILE"
sed -i '' 's/Protonmail share develop//g' "$PROJECT_FILE"
sed -i '' 's/protonmail share Production//g' "$PROJECT_FILE"

sed -i '' 's/ProtonMail Distribution//g' "$PROJECT_FILE"
sed -i '' 's/ProtonMail Development//g' "$PROJECT_FILE"
sed -i '' 's/ProtonMail Dev//g' "$PROJECT_FILE"
sed -i '' 's/ProtonMail Release//g' "$PROJECT_FILE"

# Looks inside PROJECT_FILE for values of PROVISIONING_PROFILE_SPECIFIER that are not empty (trying to match "";)
result=$(awk -F '=' '$1 ~ /PROVISIONING_PROFILE_SPECIFIER / && $2 !~ /"";/ { print $2 }' "$PROJECT_FILE";)
if [ -z "$result" ]; then
    echo "provisioning profiles removed"
else
    red_echo "error: some provisioning profile values can still be found in '$PROJECT_FILE'"
    echo "$result"
    exit 1
fi

green_echo "Submodule update and commit changes"
git submodule update --init --recursive
git add "$PROJECT_FILE"
git commit -am "$VERSION" --quiet

green_echo "Take changes from 'stage/$VERSION' to staging"
git checkout staging
git merge --ff-only "stage/$VERSION" --quiet

green_echo "Deleting branches"
git branch -D $SOURCE
git branch -D "stage/$VERSION"

echo ""
green_echo "All changes from '$SOURCE' should be in the last commit of the 'staging' branch. Please double check."
green_echo "If everything looks ok you can push the 'staging' branch for review."
echo ""
