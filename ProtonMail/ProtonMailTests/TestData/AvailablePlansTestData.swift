// Copyright (c) 2024 Proton Technologies AG
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

enum AvailablePlansTestData {
    static func availablePlans(named names: [String]) -> [String: Any] {
        [
            "Plans": names.map(availablePlan(named:))
        ]
    }

    static func availablePlan(named name: String) -> [String: Any] {
        [
            "name": "\(name)",
            "Title": "Mail Plus",
            "Instances": [
                [
                    "Price": [],
                    "Description": "Miesięcznie",
                    "Cycle": 1,
                    "Vendors": [
                        "Apple": [
                            "ProductID": "iosmail_\(name)_1_usd_auto_renewing"
                        ]
                    ],
                    "PeriodEnd": 0
                ],
                [
                    "Price": [],
                    "Description": "Rocznie",
                    "Cycle": 12,
                    "Vendors": [
                        "Apple": [
                            "ProductID": "iosmail_\(name)_12_usd_auto_renewing"
                        ]
                    ],
                    "PeriodEnd": 0
                ]
            ],
            "Entitlements": [],
            "Decorations": []
        ]
    }
}
