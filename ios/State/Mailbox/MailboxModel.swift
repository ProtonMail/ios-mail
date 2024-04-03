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

import SwiftUI

/**
 Source of truth for the Mailbox view. Contains a model for conversations and another one for messages.
 */
final class MailboxModel: ObservableObject {
    @ObservedObject private(set) var appRoute: AppRoute

    let conversationModel: MailboxConversationModel
    // let messageModel: MailboxMessageModel

    let selectionMode: SelectionMode

    init(appRoute: AppRoute) {
        self.appRoute = appRoute
        let selectionMode = SelectionMode()
        self.selectionMode = selectionMode
        self.conversationModel = MailboxConversationModel(appRoute: appRoute, selectionMode: selectionMode)
    }

    // Init for preview purposes only
    init(appRoute: AppRoute, state: MailboxConversationModel.State) {
        let selection = SelectionMode()
        self.selectionMode = selection
        self.conversationModel = MailboxConversationModel(appRoute: appRoute, selectionMode: selection, state: state)
        self.appRoute = conversationModel.appRoute
    }
}
