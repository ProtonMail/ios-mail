// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

enum FeatureFlagTestData {
    static let data: [String: Any] = [
        "Total": 5,
        "Code": 1000,
        "Features": [
            [
                "Writable": false,
                "Type": "boolean",
                "Value": true,
                "Global": true,
                "Code": "ShowSenderImages",
                "DefaultValue": true
            ],
            [
                "Writable": false,
                "Type": "boolean",
                "Value": true,
                "Global": true,
                "Code": "ScheduledSendFreemium",
                "DefaultValue": true
            ],
            [
                "Writable": false,
                "Type": "boolean",
                "Value": false,
                "Global": true,
                "Code": "ModernizedCoreData",
                "DefaultValue": false
            ],
            [
                "Writable": false,
                "Type": "boolean",
                "Value": false,
                "Global": true,
                "Code": "SendMessageRefactor",
                "DefaultValue": false
            ],
            [
                "Writable": true,
                "Type": "boolean",
                "Value": false,
                "Global": false,
                "Code": "RatingIOSMail",
                "DefaultValue": false
            ],
            [
                "Writable": true,
                "Type": "boolean",
                "Value": false,
                "Global": false,
                "Code": "ReferralActionSheetShouldBePresentedIOS",
                "DefaultValue" :false
            ],
            [
                "Writable": false,
                "Type": "boolean",
                "Value": false,
                "Global": true,
                "Code": "ProtonUnreachableBanner",
                "DefaultValue": false
            ],
            [
                "Writable": false,
                "Type": "integer",
                "Value": 0,
                "Global": true,
                "Code": "iOSMailboxPrefetchSize",
                "DefaultValue": 0
            ],
            [
                "Writable": false,
                "Type": "boolean",
                "Value": true,
                "Global": true,
                "Code": "iOSRefetchEventsByTime",
                "DefaultValue": true
            ],
            [
                "Writable": false,
                "Type": "integer",
                "Value": 24,
                "Global": true,
                "Code": "iOSRefetchEventsHourThreshold",
                "DefaultValue": 24
            ],
            [
                "Writable": false,
                "Type": "integer",
                "Value": 100,
                "Global": true,
                "Code": "iOSMailboxSelectionLimitation",
                "DefaultValue": 100
            ],
            [
                "Type": "boolean",
                "Value": true,
                "Global": true,
                "Code": "iOSAttachmentsPreviewIsEnabled",
                "DefaultValue": false
            ],
            [
                "Writable": false,
                "Type": "boolean",
                "Value": true,
                "Global": true,
                "Code": "iOSMessageNavigation",
                "DefaultValue": true
            ],
            [
                "Writable": true,
                "Type": "Any",
                "Value": ["day-45": 2, "day-30": 1, "day-7": 2],
                "Global": true,
                "Code": "AutoDowngradeReminder",
                "DefaultValue": [:]
            ]
        ] as [[String: Any]]
    ]
}
