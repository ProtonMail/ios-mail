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

@testable import ProtonMail

class DeleteActionsSpy {

    private(set) var deletedMessagesWithIDs: [ID] = []
    private(set) var deletedConversationsWithIDs: [ID] = []

    private(set) lazy var testingInstance = DeleteActions(
        message: { _, ids in
            self.deletedMessagesWithIDs = ids
            return .ok
        },
        conversation: { _, ids in
            self.deletedConversationsWithIDs = ids
            return .ok
        }
    )

}

class ReadActionPerformerActionsSpy {

    private(set) var markMessageAsReadInvoked: [ID] = []
    private(set) var markConversationAsReadInvoked: [ID] = []
    private(set) var markMessageAsUnreadInvoked: [ID] = []
    private(set) var markConversationAsUnreadInvoked: [ID] = []

    private(set) lazy var testingInstance = ReadActionPerformerActions(
        markMessageAsRead: { _, ids in
            self.markMessageAsReadInvoked = ids
            return .ok
        },
        markConversationAsRead: { _, ids in
            self.markConversationAsReadInvoked = ids
            return .ok
        },
        markMessageAsUnread: { _, ids in
            self.markMessageAsUnreadInvoked = ids
            return .ok
        },
        markConversationAsUnread: { _, ids in
            self.markConversationAsUnreadInvoked = ids
            return .ok
        }
    )

}
