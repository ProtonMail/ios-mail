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

import Combine
import proton_app_uniffi

class MessageConversationActionsModel: ObservableObject {
    @Published var state: MessageConversationSheetState
    private let actionsProvider: MessageConversationActionsProvider
    private let input: MessageConversationSheetInput

    init(mailbox: Mailbox, input: MessageConversationSheetInput) {
        self.actionsProvider = .init(mailbox: mailbox)
        self.state = .initial(title: input.title)
        self.input = input
    }
}

private extension MessageConversationSheetState {
    static func initial(title: String) -> Self {
        .init(
            title: title,
            availableActions: .init(
                replyActions: [],
                messageConversationActions: [],
                moveActions: [],
                generalActions: []
            )
        )
    }
}
