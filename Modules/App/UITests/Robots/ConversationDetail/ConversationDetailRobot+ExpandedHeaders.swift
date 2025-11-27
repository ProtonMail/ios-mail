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

extension ConversationDetailRobot {
    // MARK: Assertions

    func verifyExpandedHeader(_ entry: UITestConversationExpandedHeaderEntry) {
        let model = UITestConversationExpandedHeaderEntryModel(index: entry.index)
        model.hasSenderName(entry.senderName)
        model.hasSenderAddress(entry.senderAddress)

        if let ccRecipients = entry.ccRecipients {
            model.hasRecipients(ofType: .cc, recipients: ccRecipients)
        } else {
            model.hasNoRecipients(ofType: .cc)
        }

        if let bccRecipients = entry.bccRecipients {
            model.hasRecipients(ofType: .bcc, recipients: bccRecipients)
        } else {
            model.hasNoRecipients(ofType: .bcc)
        }

        model.hasDate(entry.timestamp)
    }

    func tapSender() {
        let model = UITestConversationExpandedHeaderEntryModel(index: 0)
        model.tapSender()
    }

    func tapRecipient(ofType type: UITestsRecipientsFieldType, atIndex index: Int) {
        let model = UITestConversationExpandedHeaderEntryModel(index: 0)
        model.tapRecipient(ofType: type, atPosition: index)
    }
}
