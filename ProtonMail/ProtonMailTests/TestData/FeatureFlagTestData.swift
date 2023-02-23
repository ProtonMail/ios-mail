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
    static let data = """
{
    "Code": 1000,
    "Features": [
        {
            "Code": "ThreadingIOS",
            "Type": "boolean",
            "Global": true,
            "DefaultValue": true,
            "Value": true,
            "Writable": true
        },
        {
            "Code": "TestInteger",
            "Type": "integer",
            "Global": 1,
            "DefaultValue": 1,
            "Value": 1,
            "UpdateTime": 1638767627,
            "Writable": true
        },
        {
            "Code": "ScheduledSendFreemium",
            "Type": "boolean",
            "Global": true,
            "DefaultValue": true,
            "Value": true,
            "Writable": true
        },
        {
            "Code": "RealNumAttachments",
            "Type": "boolean",
            "Global": true,
            "DefaultValue": true,
            "Value": true,
            "Writable": true
        }
    ],
    "Total": 14
}
"""
}
