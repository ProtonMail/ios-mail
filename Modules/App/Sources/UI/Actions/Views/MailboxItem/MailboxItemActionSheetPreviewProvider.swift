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

import proton_app_uniffi

enum MailboxItemActionSheetPreviewProvider {
    static func testData() -> MailboxItemActionSheetModel {
        MailboxItemActionSheetModel(
            input: .init(ids: [], type: .message, title: "Hello".notLocalized),
            mailbox: .init(noPointer: .init()),
            actionsProvider: ActionsProvider(
                message: { _, _ in .init(
                    replyActions: [.reply, .forward, .replyAll],
                    messageActions: [.markUnread, .star, .pin, .labelAs],
                    moveActions: [
                        .init(localId: .init(value: 1), name: .inbox, isSelected: .unselected),
                        .init(localId: .init(value: 2), name: .archive, isSelected: .unselected),
                        .init(localId: .init(value: 3), name: .spam, isSelected: .unselected),
                        .init(localId: .init(value: 4), name: .trash, isSelected: .unselected),
                    ],
                    generalActions: [
                        .viewMessageInLightMode,
                        .viewMessageInDarkMode,
                        .saveAsPdf,
                        .print,
                        .viewHeaders,
                        .viewHtml,
                        .reportPhishing
                    ]
                ) },
                conversation: { _, _ in .init(
                    replyActions: [],
                    conversationActions: [],
                    moveActions: [],
                    generalActions: []
                ) }
            ),
            starActionPerformerActions: .init(
                starMessage: { _, _ in },
                starConversation: { _, _ in },
                unstarMessage: { _, _ in },
                unstarConversation: { _, _ in }
            ), 
            readActionPerformerActions: .init( 
                markMessageAsRead: { _, _ in },
                markConversationAsRead: { _, _ in },
                markMessageAsUnread: { _, _ in },
                markConversationAsUnread: { _, _ in }
            ),
            mailUserSession: MailUserSession(noPointer: .init()),
            navigation: { _ in }
        )
    }
}
