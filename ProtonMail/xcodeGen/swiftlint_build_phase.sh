#/bin/bash

if [ "${SWIFT_SUPPRESS_WARNINGS}" != "YES" ]; then
    "$SRCROOT"/xcodeGen/swiftlint.sh
fi
