// Copyright (c) 2023 Proton Technologies AG
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

enum MailboxItemGroup {
    case conversations([ConversationEntity])
    case messages([MessageEntity])
    case empty

    init(mailboxItems: [MailboxItem]) {
        switch mailboxItems.first {
        case .none:
            self = .empty
        case .message:
            let messages: [MessageEntity] = mailboxItems.compactMap { mailboxItem in
                switch mailboxItem {
                case .message(let message):
                    return message
                case .conversation:
                    assertionFailure("mailboxItems are not homogeneous!")
                    return nil
                }
            }
            self = .messages(messages)
        case .conversation:
            let conversations: [ConversationEntity] = mailboxItems.compactMap { mailboxItem in
                switch mailboxItem {
                case .conversation(let conversation):
                    return conversation
                case .message:
                    assertionFailure("mailboxItems are not homogeneous!")
                    return nil
                }
            }
            self = .conversations(conversations)
        }
    }
}
