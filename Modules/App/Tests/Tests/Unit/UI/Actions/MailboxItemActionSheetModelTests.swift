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
import proton_app_uniffi
import XCTest

class MailboxItemActionSheetModelTests: BaseTestCase {

    var invokedWithMessagesIDs: [ID] = []
    var invokedWithConversationIDs: [ID] = []
    var spiedNavigation: [MailboxItemActionSheetNavigation] = []
    var stubbedMessageActions: MessageAvailableActions!
    var stubbedConversationActions: ConversationAvailableActions!

    func testState_WhenMailboxTypeIsMessage_ItReturnsAvailableMessageActions() {
        stubbedMessageActions = .init(
            replyActions: [.reply],
            messageActions: [.delete],
            moveActions: [],
            generalActions: [.print]
        )

        let messagesIDs: [ID] = [.init(value: 7), .init(value: 88)]
        let title = "Message title"
        let sut = sut(ids: messagesIDs, type: .message, title: title)

        sut.handle(action: .viewAppear)

        XCTAssertEqual(invokedWithMessagesIDs, messagesIDs)
        XCTAssertEqual(invokedWithConversationIDs, [])
        XCTAssertEqual(sut.state, .init(
            title: title,
            availableActions: .init(
                replyActions: [.reply],
                mailboxItemActions: [.delete],
                moveActions: .mocked(),
                generalActions: [.print]
            )
        ))
    }

    func testState_WhenMailboxTypeIsConversation_ItReturnsAvailableConversationActions() {
        stubbedConversationActions = .init(
            replyActions: [.forward],
            conversationActions: [.labelAs],
            moveActions: [],
            generalActions: [.saveAsPdf]
        )

        let conversationIDs: [ID] = [.init(value: 8), .init(value: 88)]
        let title = "Conversation title"
        let sut = sut(ids: conversationIDs, type: .conversation, title: title)

        sut.handle(action: .viewAppear)

        XCTAssertEqual(invokedWithMessagesIDs, [])
        XCTAssertEqual(invokedWithConversationIDs, conversationIDs)
        XCTAssertEqual(sut.state, .init(
            title: title,
            availableActions: .init(
                replyActions: [.forward],
                mailboxItemActions: [.labelAs],
                moveActions: .mocked(),
                generalActions: [.saveAsPdf]
            )
        ))
    }

    func testNavigation_WhenStarMailboxActionIsHandled_ItDoesNotEmitCorrectNavigation() {
        let sut = sut(ids: [], type: .message, title: .notUsed)

        sut.handle(action: .mailbox(.star))

        XCTAssertEqual(spiedNavigation, [])
    }

    func testNavigation_WhenLabelAsMailboxActionIsHandled_ItEmitsCorrectNavigation() {
        let sut = sut(ids: [], type: .message, title: .notUsed)

        sut.handle(action: .mailbox(.labelAs))

        XCTAssertEqual(spiedNavigation, [.labelAs])
    }

    private func sut(ids: [ID], type: MailboxItemType, title: String) -> MailboxItemActionSheetModel {
        MailboxItemActionSheetModel(
            input: .init(ids: ids, type: type, title: title),
            mailbox: .init(noPointer: .init()),
            actionsProvider: .init(
                message: { _, ids in
                    self.invokedWithMessagesIDs = ids
                    return self.stubbedMessageActions
                },
                conversation: { _, ids in
                    self.invokedWithConversationIDs = ids
                    return self.stubbedConversationActions
                }
            ),
            navigation: { navigation in self.spiedNavigation.append(navigation) }
        )
    }

}
