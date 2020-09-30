#!/bin/sh

#  Script.sh
#  ProtonMail
#
#  Created by denys zelenchuk on 23.09.20.
#  Copyright © 2020 ProtonMail. All rights reserved.

echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">' > credentials.plist

echo "<dict>
            <key>TEST_USER1</key>
            <string>$TEST_USER1</string>
            <key>TEST_USER2</key>
            <string>$TEST_USER2</string>
            <key>TEST_USER3</key>
            <string>$TEST_USER3</string>
            <key>TEST_USER4</key>
            <string>$TEST_USER4</string>
            <key>TEST_RECIPIENT1</key>
            <string>$TEST_RECIPIENT1</string>
            <key>TEST_RECIPIENT2</key>
            <string>$TEST_RECIPIENT2</string>
            <key>TEST_RECIPIENT3</key>
            <string>$TEST_RECIPIENT3</string>
            <key>TEST_RECIPIENT4</key>
            <string>$TEST_RECIPIENT4</string>
        </dict>" >> credentials.plist

echo '</plist>' >> credentials.plist

