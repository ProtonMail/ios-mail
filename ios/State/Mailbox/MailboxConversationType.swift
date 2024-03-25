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

protocol MailboxConversationType: AnyObject {
    var input: MailboxConversationInput { get }
    var output: MailboxConversationOutput { get }
}

protocol MailboxConversationInput {

    @MainActor
    func onConversationSelectionChange(id: PMLocalConversationId, isSelected: Bool)

    @MainActor
    func onConversationStarChange(id: PMLocalConversationId, isStarred: Bool)

    @MainActor
    func onAttachmentTap(attachmentId: String)

    @MainActor
    func onConversationsDeletion(ids: [PMLocalConversationId])

    @MainActor
    func onConversationsSetReadStatus(to newStatus: MailboxReadStatus, for ids: [PMLocalConversationId])

    @MainActor
    func onConversationAction(
        _ swipeAction: SwipeAction,
        conversationId: PMLocalConversationId,
        newReadStatus: MailboxReadStatus?
    )
}

protocol MailboxConversationOutput {

    var state: MailboxConversationModel.State { get }
}
