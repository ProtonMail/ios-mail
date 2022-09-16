#!/bin/sh
if [ ${CONFIGURATION} == "Debug" ]; then
buildNumber=${CONFIGURATION}
fi;
if [ ${CONFIGURATION} == "Release" ]; then
cd ${SRCROOT}
buildNumber="$(git rev-list HEAD | wc -l | tr -d ' ')"
fi;
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${SRCROOT}/ProtonMail/Supporting Files/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${SRCROOT}/PushService/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${SRCROOT}/Share/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${SRCROOT}/Siri/Info.plist"
