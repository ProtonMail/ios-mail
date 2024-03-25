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

/**
 Source of truth for the Mailbox view. Contains a model for conversations and another one for messages.
 */
final class MailboxModel: ObservableObject {
    let conversationModel: MailboxConversationModel
    // let messageModel: MailboxMessageModel

    @Published private(set) var selectedMailbox: SelectedMailbox

    init() {
        let initialMailbox = SelectedMailbox.defaultMailbox
        self.selectedMailbox = initialMailbox
        self.conversationModel = .init(selectedMailbox: initialMailbox)
    }

    func initialDataFetch() async {
        await updateSelectedMailbox(selectedMailbox)
    }

    @MainActor
    func updateSelectedMailbox(_ selectedMailbox: SelectedMailbox) async {
        self.selectedMailbox = selectedMailbox
        do {
            try await conversationModel.updateMailboxAndFetchData(selectedMailbox: selectedMailbox)
        } catch {
            AppLogger.log(error: error, category: .mailboxConversations)
        }
    }
}
