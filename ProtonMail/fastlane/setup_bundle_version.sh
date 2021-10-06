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
if [ "$1" ] 
then
    echo $1
else 
    echo $BUNDLE_VERSION
fi  

for name in "${FOLDERS[@]}"
do
    PLIST="$PWD/$name/Info.plist"
    DEVPLIST="$PWD/$name/InfoDev.plist"

    if [ "$1" ] 
    then
        /usr/libexec/PlistBuddy -c "Set CFBundleVersion $1" "$PLIST"
        /usr/libexec/PlistBuddy -c "Set CFBundleVersion $1" "$DEVPLIST"
    else 
        /usr/libexec/PlistBuddy -c "Set CFBundleVersion $BUNDLE_VERSION" "$PLIST"
        /usr/libexec/PlistBuddy -c "Set CFBundleVersion $BUNDLE_VERSION" "$DEVPLIST"
    fi  
done
cd fastlane