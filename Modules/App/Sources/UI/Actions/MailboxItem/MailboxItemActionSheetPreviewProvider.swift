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
        let model = MailboxItemActionSheetModel(
            mailbox: .init(noPointer: .init()),
            actionsProvider: ActionsProvider(
                message: { _, _ in .init(
                    replyActions: [],
                    messageActions: [],
                    moveActions: [],
                    generalActions: []
                ) },
                conversation: { _, _ in .init(
                    replyActions: [],
                    conversationActions: [],
                    moveActions: [],
                    generalActions: []
                ) }
            ),
            input: .init(ids: [], type: .message, title: "Hello".notLocalized)
        )
        model.state = .init(
            title: "Hello".notLocalized,
            availableActions: .init(
                replyActions: [.reply, .forward, .replyAll],
                mailboxItemActions: [.markUnread, .star, .pin, .labelAs],
                moveActions: [
                    .system(.init(localId: .random(), systemLabel: .inbox)),
                    .system(.init(localId: .random(), systemLabel: .archive)),
                    .system(.init(localId: .random(), systemLabel: .spam)),
                    .system(.init(localId: .random(), systemLabel: .trash)),
                    .moveTo
                ],
                generalActions: [
                    .viewMessageInLightMode,
                    .saveAsPdf,
                    .print,
                    .viewHeaders,
                    .viewHtml,
                    .reportPhishing
                ]
            )
        )
        return model
    }
}
