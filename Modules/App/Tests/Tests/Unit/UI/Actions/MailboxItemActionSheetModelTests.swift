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
import InboxTesting
import proton_app_uniffi
import XCTest

class MailboxItemActionSheetModelTests: BaseTestCase {

    var invokedWithMessagesIDs: [ID]!
    var invokedWithConversationIDs: [ID]!
    var spiedNavigation: [MailboxItemActionSheetNavigation]!
    var stubbedMessageActions: MessageAvailableActions!
    var stubbedConversationActions: ConversationAvailableActions!

    var starActionPerformerActionsSpy: StarActionPerformerActionsSpy!
    var readActionPerformerActionsSpy: ReadActionPerformerActionsSpy!
    var deleteActionsSpy: DeleteActionsSpy!

    override func setUp() {
        super.setUp()

        invokedWithMessagesIDs = []
        invokedWithConversationIDs = []
        spiedNavigation = []

        starActionPerformerActionsSpy = .init()
        readActionPerformerActionsSpy = .init()
        deleteActionsSpy = .init()
    }

    override func tearDown() {
        super.tearDown()

        invokedWithMessagesIDs = nil
        invokedWithConversationIDs = nil
        spiedNavigation = nil
        stubbedMessageActions = nil
        stubbedConversationActions = nil

        starActionPerformerActionsSpy = nil
        readActionPerformerActionsSpy = nil
        deleteActionsSpy = nil
    }

    func testState_WhenMailboxTypeIsMessage_ItReturnsAvailableMessageActions() {
        stubbedMessageActions = .init(
            replyActions: [.reply],
            messageActions: [.delete],
            moveActions: [
                .moveToSystemFolder(.init(localId: .init(value: 1), name: .inbox)), 
                .moveTo
            ],
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
                moveActions: [.system(.init(localId: .init(value: 1), systemLabel: .inbox)), .moveTo],
                generalActions: [.print]
            )
        ))
    }

    func testState_WhenMailboxTypeIsConversation_ItReturnsAvailableConversationActions() {
        stubbedConversationActions = .init(
            conversationActions: [.labelAs],
            moveActions: [
                .moveToSystemFolder(.init(localId: .init(value: 1), name: .inbox)),
                .moveTo
            ],
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
                replyActions: nil,
                mailboxItemActions: [.labelAs],
                moveActions: [.system(.init(localId: .init(value: 1), systemLabel: .inbox)), .moveTo],
                generalActions: [.saveAsPdf]
            )
        ))
    }

    func testNavigation_WhenLabelAsMailboxActionIsHandled_ItEmitsCorrectNavigation() {
        let sut = sut(ids: [], type: .message, title: .notUsed)

        sut.handle(action: .mailboxItemActionSelected(.labelAs))

        XCTAssertEqual(spiedNavigation, [.labelAs])
    }

    func testStarAction_WhenMessageIsStarred_ItStarsMessage() {
        test(
            action: .star,
            itemType: .message,
            verifyInvoked: { starActionPerformerActionsSpy.invokedStarMessage }
        )
    }

    func testUnstarAction_WhenMessageIsUnstarred_ItUnstarsMessage() {
        test(
            action: .unstar,
            itemType: .message,
            verifyInvoked: { starActionPerformerActionsSpy.invokedUnstarMessage }
        )
    }

    func testStarAction_WhenConversationIsStarred_ItStarsConversation() {
        test(
            action: .star,
            itemType: .conversation,
            verifyInvoked: { starActionPerformerActionsSpy.invokedStarConversation }
        )
    }

    func testUnstarAction_WhenConversationIsUnstarred_ItUnstarsConversation() {
        test(
            action: .unstar,
            itemType: .conversation,
            verifyInvoked: { starActionPerformerActionsSpy.invokedUnstarConversation }
        )
    }

    func testMarkAsReadAction_WhenMessageIsMarkedAsRead_ItMarksMessageAsRead() {
        test(
            action: .markRead,
            itemType: .message,
            verifyInvoked: { readActionPerformerActionsSpy.markMessageAsReadInvoked }
        )
    }

    func testMarkAsReadAction_WhenConversationIsMarkedAsRead_ItMarksConversationAsRead() {
        test(
            action: .markRead,
            itemType: .conversation,
            verifyInvoked: { readActionPerformerActionsSpy.markConversationAsReadInvoked }
        )
    }

    func testMarkAsUnreadAction_WhenMessageIsMarkedAsUnread_ItMarksMessageAsUnread() {
        test(
            action: .markUnread,
            itemType: .message,
            verifyInvoked: { readActionPerformerActionsSpy.markMessageAsUnreadInvoked }
        )
    }

    func testMarkAsUnreadAction_WhenConversationIsMarkedAsUnread_ItMarksConversationAsUnread() {
        test(
            action: .markUnread,
            itemType: .conversation,
            verifyInvoked: { readActionPerformerActionsSpy.markConversationAsUnreadInvoked }
        )
    }

    func testDeleteAction_WhenConversationIsDeleted_ItDeletesConversation() {
        testDeletionFlow(
            itemType: .conversation,
            verifyInvoked: { deleteActionsSpy.deletedConversationsWithIDs }
        )
    }

    func testDeleteAction_WhenMessageIsDeleted_ItDeletesMessage() {
        testDeletionFlow(
            itemType: .message,
            verifyInvoked: { deleteActionsSpy.deletedMessagesWithIDs }
        )
    }

    // MARK: - Private

    private func test(action: MailboxItemAction_v2, itemType: MailboxItemType, verifyInvoked: () -> [ID]) {
        let ids: [ID] = [.init(value: 55), .init(value: 5)]
        let sut = sut(ids: ids, type: itemType, title: .notUsed)

        sut.handle(action: .mailboxItemActionSelected(action))

        XCTAssertEqual(verifyInvoked(), ids)
        XCTAssertEqual(spiedNavigation, [.dismiss])
    }

    private func testDeletionFlow(itemType: MailboxItemType, verifyInvoked: () -> [ID]) {
        let ids: [ID] = [.init(value: 55), .init(value: 5)]
        let sut = sut(ids: ids, type: itemType, title: .notUsed)

        sut.handle(action: .mailboxItemActionSelected(.delete))

        XCTAssertNotNil(sut.state.deleteConfirmationAlert) // FIXME: - Update later

        sut.handle(action: .alertActionTapped(.delete))

        XCTAssertEqual(verifyInvoked(), ids)
        XCTAssertEqual(spiedNavigation, [.dismiss])
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
            starActionPerformerActions: starActionPerformerActionsSpy.testingInstance, 
            readActionPerformerActions: readActionPerformerActionsSpy.testingInstance, 
            deleteActions: deleteActionsSpy.testingInstance,
            mailUserSession: .dummy,
            navigation: { navigation in self.spiedNavigation.append(navigation) }
        )
    }

}
