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

enum ConversationDetailSeed {
    case mailboxItem(item: MailboxItemCellUIModel, selectedMailbox: SelectedMailbox)
    case message(localID: ID, subject: String, sender: String)

    var selectedMailbox: SelectedMailbox {
        switch self {
        case .mailboxItem(_, let selectedMailbox):
            return selectedMailbox
        case .message:
            return .inbox
        }
    }

    var subject: String {
        switch self {
        case .mailboxItem(let model, _):
            return model.subject
        case .message(_, let subject, _):
            return subject
        }
    }

    var isStarStateKnown: Bool {
        if case .mailboxItem = self {
            return true
        }
        return false
    }

    var isStarred: Bool {
        switch self {
        case .mailboxItem(let model, _):
            return model.isStarred
        case .message:
            return false
        }
    }

    var numAttachments: Int {
        switch self {
        case .mailboxItem(let model, _):
            return model.attachmentsUIModel.count
        case .message:
            return 0
        }
    }

    var hasNoAttachments: Bool {
        numAttachments == 0
    }

    var labels: [LabelUIModel] {
        switch self {
        case .mailboxItem(let model, _):
            model.labelUIModel.labelModels
        case .message:
            []
        }
    }
}
