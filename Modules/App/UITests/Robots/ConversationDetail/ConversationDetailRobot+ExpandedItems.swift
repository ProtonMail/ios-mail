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
    // MARK: Actions

    func tapThreeDots(at index: Int) {
        let model = UITestConversationExpandedItemEntryModel(
            index: index
        )

        model.tapThreeDots()
    }

    func tapExpandedEntry(at index: Int) {
        let model = UITestConversationExpandedItemEntryModel(
            index: index
        )

        model.toggleItem()
    }

    // MARK: Assertions

    func hasExpandedEntries(indexes: Int...) {
        for index in indexes {
            let model = UITestConversationExpandedItemEntryModel(index: index)
            model.isDisplayed()
        }
    }

    func verifyExpandedEntries(_ entries: [UITestConversationExpandedItemEntry]) {
        for entry in entries {
            verifyEntry(entry)
        }
    }

    private func verifyEntry(_ entry: UITestConversationExpandedItemEntry) {
        let model = UITestConversationExpandedItemEntryModel(
            index: entry.index
        )

        model.isDisplayed()
        model.hasSenderName(entry.senderName)
        model.hasSenderAddress(entry.senderAddress)
        model.hasDate(entry.date)
        model.hasRecipientsSummary(entry.recipientsSummary)
    }
}
