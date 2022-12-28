// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

enum MailboxItem: Hashable {
    case message(MessageEntity)
    case conversation(ConversationEntity)

    var isScheduledForSending: Bool {
        switch self {
        case .message(let message):
            return message.isScheduledSend
        case .conversation(let conversation):
            return conversation.contains(of: .scheduled)
        }
    }

    var isStarred: Bool {
        switch self {
        case .message(let message):
            return message.isStarred
        case .conversation(let conversation):
            return conversation.starred
        }
    }

    var itemID: String {
        switch self {
        case .message(let message):
            return message.messageID.rawValue
        case .conversation(let conversation):
            return conversation.conversationID.rawValue
        }
    }

    var objectID: ObjectID {
        switch self {
        case .message(let message):
            return message.objectID
        case .conversation(let conversation):
            return conversation.objectID
        }
    }

    func isUnread(labelID: LabelID) -> Bool {
        switch self {
        case .message(let message):
            return message.unRead
        case .conversation(let conversation):
            return conversation.isUnread(labelID: labelID)
        }
    }
}
