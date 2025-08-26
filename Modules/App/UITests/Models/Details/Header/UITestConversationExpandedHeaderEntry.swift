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

import Foundation

struct UITestConversationExpandedHeaderEntry {
    let index: Int
    let senderName: String
    let senderAddress: String
    let timestamp: UInt64
    let toRecipients: [UITestHeaderRecipientEntry]
    let ccRecipients: [UITestHeaderRecipientEntry]?
    let bccRecipients: [UITestHeaderRecipientEntry]?

    init(
        index: Int, senderName: String, senderAddress: String, timestamp: UInt64, toRecipients: [UITestHeaderRecipientEntry], ccRecipients: [UITestHeaderRecipientEntry]? = nil,
        bccRecipients: [UITestHeaderRecipientEntry]? = nil
    ) {
        self.index = index
        self.senderName = senderName
        self.senderAddress = senderAddress
        self.timestamp = timestamp
        self.toRecipients = toRecipients
        self.ccRecipients = ccRecipients
        self.bccRecipients = bccRecipients
    }
}
