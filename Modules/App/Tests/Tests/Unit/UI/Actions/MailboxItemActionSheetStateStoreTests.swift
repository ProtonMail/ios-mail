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
import InboxCoreUI
import InboxTesting
import proton_app_uniffi
import XCTest

class MailboxItemActionSheetStateStoreTests: BaseTestCase {

    var invokedWithMessagesIDs: [ID]!
    var invokedWithConversationIDs: [ID]!
    var spiedNavigation: [MailboxItemActionSheetNavigation]!
    var stubbedMessageActions: MessageAvailableActions!
    var stubbedConversationActions: ConversationAvailableActions!

    var starActionPerformerActionsSpy: StarActionPerformerActionsSpy!
    var readActionPerformerActionsSpy: ReadActionPerformerActionsSpy!
    var deleteActionsSpy: DeleteActionsSpy!
    var moveToActionsSpy: MoveToActionsSpy!
    var toastStateStore: ToastStateStore!

    override func setUp() {
        super.setUp()

        invokedWithMessagesIDs = []
        invokedWithConversationIDs = []
        spiedNavigation = []

        starActionPerformerActionsSpy = .init()
        readActionPerformerActionsSpy = .init()
        deleteActionsSpy = .init()
        moveToActionsSpy = .init()
        toastStateStore = .init(initialState: .initial)
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
        moveToActionsSpy = nil
        toastStateStore = nil
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

        sut.handle(action: .onLoad)

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

        sut.handle(action: .onLoad)

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
            expectedNavigation: .dismiss,
            verifyInvoked: { starActionPerformerActionsSpy.invokedStarMessage }
        )
    }

    func testUnstarAction_WhenMessageIsUnstarred_ItUnstarsMessage() {
        test(
            action: .unstar,
            itemType: .message, 
            expectedNavigation: .dismiss,
            verifyInvoked: { starActionPerformerActionsSpy.invokedUnstarMessage }
        )
    }

    func testStarAction_WhenConversationIsStarred_ItStarsConversation() {
        test(
            action: .star,
            itemType: .conversation, 
            expectedNavigation: .dismiss,
            verifyInvoked: { starActionPerformerActionsSpy.invokedStarConversation }
        )
    }

    func testUnstarAction_WhenConversationIsUnstarred_ItUnstarsConversation() {
        test(
            action: .unstar,
            itemType: .conversation, 
            expectedNavigation: .dismiss,
            verifyInvoked: { starActionPerformerActionsSpy.invokedUnstarConversation }
        )
    }

    func testMarkAsReadAction_WhenMessageIsMarkedAsRead_ItMarksMessageAsRead() {
        test(
            action: .markRead,
            itemType: .message, 
            expectedNavigation: .dismiss,
            verifyInvoked: { readActionPerformerActionsSpy.markMessageAsReadInvoked }
        )
    }

    func testMarkAsReadAction_WhenConversationIsMarkedAsRead_ItMarksConversationAsRead() {
        test(
            action: .markRead,
            itemType: .conversation, 
            expectedNavigation: .dismiss,
            verifyInvoked: { readActionPerformerActionsSpy.markConversationAsReadInvoked }
        )
    }

    func testMarkAsUnreadAction_WhenMessageIsMarkedAsUnread_ItMarksMessageAsUnread() {
        test(
            action: .markUnread,
            itemType: .message, 
            expectedNavigation: .dismiss,
            verifyInvoked: { readActionPerformerActionsSpy.markMessageAsUnreadInvoked }
        )
    }

    func testMarkAsUnreadAction_WhenConversationIsMarkedAsUnread_ItMarksConversationAsUnread() {
        test(
            action: .markUnread,
            itemType: .conversation, 
            expectedNavigation: .dismissAndGoBack,
            verifyInvoked: { readActionPerformerActionsSpy.markConversationAsUnreadInvoked }
        )
    }

    func testDeleteAction_WhenConversationIsDeleted_ItDeletesConversation() {
        testDeletionFlow(
            itemType: .conversation,
            action: .mailboxItemActionSelected(.delete),
            expectedNavigation: .dismissAndGoBack,
            verifyInvoked: { deleteActionsSpy.deletedConversationsWithIDs }
        )
    }

    func testDeleteAction_WhenMessageIsDeleted_ItDeletesMessage() {
        testDeletionFlow(
            itemType: .message,
            action: .mailboxItemActionSelected(.delete), 
            expectedNavigation: .dismiss,
            verifyInvoked: { deleteActionsSpy.deletedMessagesWithIDs }
        )
    }

    func testMoveToDeleteAction_WhenMeesageIsDeleted_ItDeletesMessage() {
        testDeletionFlow(
            itemType: .message,
            action: .moveTo(.permanentDelete), 
            expectedNavigation: .dismiss,
            verifyInvoked: { deleteActionsSpy.deletedMessagesWithIDs }
        )
    }

    func testAction_WhenMessageIsMovedOutOfSpam_ItMovesMessageOutOfSpam() throws {
        try testMoveToAction(
            itemType: .message,
            action: .notSpam(.init(localId: .init(value: 1), systemLabel: .inbox)),
            verifyInvoked: { moveToActionsSpy.invokedMoveToMessage }
        )
    }

    func testAction_WhenConversationIsMovedToInbox_ItMovesConversationToInbox() throws {
        try testMoveToAction(
            itemType: .conversation,
            action: .system(.init(localId: .init(value: 1), systemLabel: .inbox)),
            verifyInvoked: { moveToActionsSpy.invokedMoveToConversation }
        )
    }
    
    // MARK: - General actions
    
    func testAction_WhenPrintMessageActionInvoked_ItShowsComingSoonBanner() {
        verifyGeneralAction(action: .print)
    }
    
    func testAction_WhenReportPhishingActionInvoked_ItShowsComingSoonBanner() {
        verifyGeneralAction(action: .reportPhishing)
    }
    
    func testAction_WhenSaveAsPdfActionInvoked_ItShowsComingSoonBanner() {
        verifyGeneralAction(action: .saveAsPdf)
    }
    
    func testAction_WhenViewHeadersActionInvoked_ItShowsComingSoonBanner() {
        verifyGeneralAction(action: .viewHeaders)
    }
    
    func testAction_WhenViewHTMLActionInvoked_ItShowsComingSoonBanner() {
        verifyGeneralAction(action: .viewHtml)
    }
    
    func testAction_WhenViewMessageInDarkModeActionInvoked_ItShowsComingSoonBanner() {
        verifyGeneralAction(action: .viewMessageInDarkMode)
    }
    
    func testAction_WhenViewMessageInLightModeActionInvoked_ItShowsComingSoonBanner() {
        verifyGeneralAction(action: .viewMessageInLightMode)
    }

    // MARK: - Private

    private func test(
        action: MailboxItemAction,
        itemType: MailboxItemType,
        expectedNavigation: MailboxItemActionSheetNavigation,
        verifyInvoked: () -> [ID]
    ) {
        let ids: [ID] = [.init(value: 55), .init(value: 5)]
        let sut = sut(ids: ids, type: itemType, title: .notUsed)

        sut.handle(action: .mailboxItemActionSelected(action))

        XCTAssertEqual(verifyInvoked(), ids)
        XCTAssertEqual(spiedNavigation, [expectedNavigation])
    }

    private func testDeletionFlow(
        itemType: MailboxItemType,
        action: MailboxItemActionSheetAction,
        expectedNavigation: MailboxItemActionSheetNavigation,
        verifyInvoked: () -> [ID]
    ) {
        let ids: [ID] = [.init(value: 55), .init(value: 5)]
        let sut = sut(ids: ids, type: itemType, title: .notUsed)

        sut.handle(action: action)

        XCTAssertEqual(sut.state.alert, .deleteConfirmation(itemsCount: ids.count, action: { _ in }))

        sut.handle(action: .alertActionTapped(.delete))

        XCTAssertEqual(verifyInvoked(), ids)
        XCTAssertEqual(spiedNavigation, [expectedNavigation])

        XCTAssertEqual(toastStateStore.state.toasts, [.deleted()])
    }

    private func testMoveToAction(
        itemType: MailboxItemType,
        action: MoveToAction,
        verifyInvoked: () -> [MoveToActionsSpy.CapturedArguments]
    ) throws {
        let ids: [ID] = [.init(value: 1), .init(value: 7)]
        let sut = sut(ids: ids, type: itemType, title: .notUsed)

        sut.handle(action: .moveTo(action))

        let destination = try XCTUnwrap(action.destination)

        XCTAssertEqual(verifyInvoked(), [.init(destinationID: destination.localId, itemsIDs: ids)])

        XCTAssertEqual(toastStateStore.state.toasts, [
            .moveTo(destinationName: destination.systemLabel.humanReadable.string)
        ])
    }
    
    private func verifyGeneralAction(action: GeneralActions) {
        let ids: [ID] = [.init(value: 1), .init(value: 7)]
        let sut = sut(ids: ids, type: .message, title: .notUsed)
        
        sut.handle(action: .mailboxGeneralActionTapped(action))
        
        XCTAssertEqual(toastStateStore.state.toasts, [.comingSoon])
    }

    private func sut(ids: [ID], type: MailboxItemType, title: String) -> MailboxItemActionSheetStateStore {
        MailboxItemActionSheetStateStore(
            input: .init(ids: ids, type: type, title: title),
            mailbox: .init(noPointer: .init()),
            actionsProvider: .init(
                message: { _, ids in
                    self.invokedWithMessagesIDs = ids
                    return .ok(self.stubbedMessageActions)
                },
                conversation: { _, ids in
                    self.invokedWithConversationIDs = ids
                    return .ok(self.stubbedConversationActions)
                }
            ),
            starActionPerformerActions: starActionPerformerActionsSpy.testingInstance,
            readActionPerformerActions: readActionPerformerActionsSpy.testingInstance,
            deleteActions: deleteActionsSpy.testingInstance,
            moveToActions: moveToActionsSpy.testingInstance,
            mailUserSession: .dummy, 
            toastStateStore: toastStateStore,
            navigation: { navigation in self.spiedNavigation.append(navigation) }
        )
    }

}

private extension MoveToAction {

    var destination: MoveToSystemFolderLocation? {
        switch self {
        case .system(let label), .notSpam(let label):
            return label
        case .moveTo, .permanentDelete:
            return nil
        }
    }

}
