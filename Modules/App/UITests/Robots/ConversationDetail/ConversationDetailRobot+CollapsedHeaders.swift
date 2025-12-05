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

    func toggleCollapsedHeader(at index: Int) {
        let model = UITestConversationCollapsedHeaderEntryModel(index: index)
        model.expand()
    }

    // MARK: Assertions

    func verifyCollapsedHeader(_ entry: UITestConversationCollapsedHeaderEntry) {
        let model = UITestConversationCollapsedHeaderEntryModel(index: entry.index)
        model.hasSenderName(entry.senderName)
        model.hasOfficialBadge(entry.hasOfficialBadge)
        model.hasDate(entry.date)
        model.hasSenderAddress(entry.senderAddress)
        model.hasToRecipientsSummary(entry.toRecipients)
    }
}
