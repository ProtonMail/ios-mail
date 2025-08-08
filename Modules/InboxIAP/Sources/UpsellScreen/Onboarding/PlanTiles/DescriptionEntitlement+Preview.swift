//
// Copyright (c) 2025 Proton Technologies AG
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

import PaymentsNG

extension Array where Element == DescriptionEntitlement {
    static let unlimited: [Element] = [
        .testData(text: "500 GB storage", iconName: "storage"),
        .testData(text: "15 email addresses", iconName: "envelope"),
        .testData(text: "Support for 3 custom email domains", iconName: "globe"),
        .testData(text: "Unlimited folders, labels, and filters", iconName: "tag"),
        .testData(text: "25 personal calendars", iconName: "calendar-checkmark"),
        .testData(text: "High-speed VPN on 10 devices per user", iconName: "shield"),
        .testData(text: "All premium features from Proton Mail, Pass, VPN, Drive, and Calendar", iconName: "checkmark"),
    ]

    static let mailPlus: [Element] = [
        .testData(text: "15 GB storage", iconName: "storage"),
        .testData(text: "10 email addresses", iconName: "envelope"),
        .testData(text: "Support for 1 custom email domain", iconName: "globe"),
        .testData(text: "Unlimited folders, labels, and filters", iconName: "tag"),
        .testData(text: "25 personal calendars", iconName: "calendar-checkmark"),
        .testData(text: "And the free features of all other Proton products!", iconName: "checkmark"),
    ]

    static let free: [Element] = [
        .testData(text: L10n.Perk.amountOfStorage(gigabytes: 1).string, iconName: "storage"),
        .testData(text: L10n.Perk.numberOfEmailAddresses(1).string, iconName: "envelope"),
    ]
}

private extension DescriptionEntitlement {
    static func testData(text: String, iconName: String) -> Self {
        .init(type: .empty, text: text, iconName: iconName, hint: nil)
    }
}

