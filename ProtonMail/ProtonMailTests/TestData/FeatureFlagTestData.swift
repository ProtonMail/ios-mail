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
                "Type": "integer",
                "Value": 1,
                "Global": true,
                "Code": "InAppFeedbackIOS",
                "DefaultValue": 0
            ],
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
            ]
        ] as [[String: Any]]
    ]
}
