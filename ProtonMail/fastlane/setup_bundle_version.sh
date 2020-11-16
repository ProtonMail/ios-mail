#!/bin/bash

# Usage
# 
# Set bundle version by number of git commit
# ./setup_bundle_version.sh 
#
# Set bundle version by given value
# ./setup_bundle_version.sh MY_VALUE


cd ..
FOLDERS=("ProtonMail/Supporting Files" "PushService" "Share" "Siri")
BUNDLE_VERSION=$(git rev-list --count HEAD)
echo $BUNDLE_VERSION

for name in "${FOLDERS[@]}"
do
    PLIST="$PWD/$name/Info.plist"

    if [ "$1" ] 
    then
        /usr/libexec/PlistBuddy -c "Set CFBundleVersion $1" "$PLIST"
    else 
        /usr/libexec/PlistBuddy -c "Set CFBundleVersion $BUNDLE_VERSION" "$PLIST"
    fi  
done
cd fastlane