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
    var generalActionsSpy: GeneralActionsPerfomerSpy!
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
        generalActionsSpy = .init()
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

        let messageID = ID(value: 7)
        let title = "Message title"
        let sut = sut(id: messageID.value, type: .message, title: title)

        sut.handle(action: .onLoad)

        XCTAssertEqual(invokedWithMessagesIDs, [messageID])
        XCTAssertEqual(invokedWithConversationIDs, [])
        XCTAssertEqual(sut.state, .init(
            title: title,
            availableActions: .init(
                replyActions: [.reply],
                mailboxItemActions: [.delete],
                moveActions: [.moveToSystemFolder(.init(localId: .init(value: 1), name: .inbox)), .moveTo],
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

        let conversationID = ID(value: 8)
        let title = "Conversation title"
        let sut = sut(id: conversationID.value, type: .conversation, title: title)

        sut.handle(action: .onLoad)

        XCTAssertEqual(invokedWithMessagesIDs, [])
        XCTAssertEqual(invokedWithConversationIDs, [conversationID])
        XCTAssertEqual(sut.state, .init(
            title: title,
            availableActions: .init(
                replyActions: nil,
                mailboxItemActions: [.labelAs],
                moveActions: [.moveToSystemFolder(.init(localId: .init(value: 1), name: .inbox)), .moveTo],
                generalActions: [.saveAsPdf]
            )
        ))
    }

    func testNavigation_WhenLabelAsMailboxActionIsHandled_ItEmitsCorrectNavigation() {
        let sut = sut(id: 99, type: .message, title: .notUsed)

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
            expectedNavigation: .dismissAndGoBack,
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
            action: .notSpam(.init(localId: .init(value: 1), name: .inbox)),
            verifyInvoked: { moveToActionsSpy.invokedMoveToMessage }
        )
    }

    func testAction_WhenConversationIsMovedToInbox_ItMovesConversationToInbox() throws {
        try testMoveToAction(
            itemType: .conversation,
            action: .moveToSystemFolder(.init(localId: .init(value: 1), name: .inbox)),
            verifyInvoked: { moveToActionsSpy.invokedMoveToConversation }
        )
    }

    // MARK: - General actions

    func testAction_WhenPrintMessageActionInvoked_ItShowsComingSoonBanner() {
        verifyGeneralAction(action: .print)
    }

    func testAction_WhenReportPhishingActionInvoked_ItPresentsConfirmPhishingAlert() {
        let id = ID(value: 55)
        let sut = sut(id: id.value, type: .message, title: .notUsed)

        sut.handle(action: .generalActionTapped(.reportPhishing))

        XCTAssertEqual(sut.state.alert, .phishingConfirmation(action: { _ in }))
    }
    
    func testAction_WhenReportPhishingActionConfirmedAndSucceeds_ItMarksMessageAsPhishingAndDismisses() async throws {
        generalActionsSpy.stubbedMarkMessagePhishingResult = .ok

        let id = ID(value: 55)
        let sut = sut(id: id.value, type: .message, title: .notUsed)

        sut.handle(action: .generalActionTapped(.reportPhishing))

        XCTAssertEqual(sut.state.alert, .phishingConfirmation(action: { _ in }))

        let confirmAction = try sut.state.alertAction(for: L10n.Common.confirm)
        await confirmAction.action()

        XCTAssertEqual(sut.state.alert, nil)
        XCTAssertEqual(generalActionsSpy.markMessagePhishingWithMessageIDCalls, [id])
        XCTAssertEqual(spiedNavigation, [.dismiss])
    }
    
    func testAction_WhenReportPhishingActionConfirmedAndFails_ItMarksMessageAsPhishingAndDoesNotDismiss() async throws {
        generalActionsSpy.stubbedMarkMessagePhishingResult = .error(.other(.network))

        let id = ID(value: 55)
        let sut = sut(id: id.value, type: .message, title: .notUsed)

        sut.handle(action: .generalActionTapped(.reportPhishing))

        XCTAssertEqual(sut.state.alert, .phishingConfirmation(action: { _ in }))

        let confirmAction = try sut.state.alertAction(for: L10n.Common.confirm)
        await confirmAction.action()
        
        XCTAssertEqual(sut.state.alert, nil)
        XCTAssertEqual(generalActionsSpy.markMessagePhishingWithMessageIDCalls, [id])
        XCTAssertEqual(spiedNavigation, [])
    }
    
    func testAction_WhenReportPhishingActionCancelled_ItDoesNotMarkMessageAsPhishingAndDoesNotDismiss() async throws {
        let id = ID(value: 55)
        let sut = sut(id: id.value, type: .message, title: .notUsed)

        sut.handle(action: .generalActionTapped(.reportPhishing))

        XCTAssertEqual(sut.state.alert, .phishingConfirmation(action: { _ in }))

        let cancelAction = try sut.state.alertAction(for: L10n.Common.cancel)
        await cancelAction.action()
        
        XCTAssertEqual(sut.state.alert, nil)
        XCTAssertEqual(generalActionsSpy.markMessagePhishingWithMessageIDCalls, [])
        XCTAssertEqual(spiedNavigation, [])
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
        let id = ID(value: 55)
        let sut = sut(id: id.value, type: itemType, title: .notUsed)

        sut.handle(action: .mailboxItemActionSelected(action))

        XCTAssertEqual(verifyInvoked(), [id])
        XCTAssertEqual(spiedNavigation, [expectedNavigation])
    }

    private func testDeletionFlow(
        itemType: MailboxItemType,
        action: MailboxItemActionSheetAction,
        expectedNavigation: MailboxItemActionSheetNavigation,
        verifyInvoked: () -> [ID]
    ) {
        let id = ID(value: 55)
        let sut = sut(id: id.value, type: itemType, title: .notUsed)

        sut.handle(action: action)

        XCTAssertEqual(sut.state.alert, .deleteConfirmation(itemsCount: 1, action: { _ in }))

        sut.handle(action: .deleteConfirmed(.delete))

        XCTAssertEqual(verifyInvoked(), [id])
        XCTAssertEqual(spiedNavigation, [expectedNavigation])

        XCTAssertEqual(toastStateStore.state.toasts, [.deleted()])
    }

    private func testMoveToAction(
        itemType: MailboxItemType,
        action: MoveToAction,
        verifyInvoked: () -> [MoveToActionsSpy.CapturedArguments]
    ) throws {
        let id = ID(value: 1)
        let sut = sut(id: id.value, type: itemType, title: .notUsed)

        sut.handle(action: .moveTo(action))

        let destination = try XCTUnwrap(action.destination)

        XCTAssertEqual(verifyInvoked(), [.init(destinationID: destination.localId, itemsIDs: [id])])

        XCTAssertEqual(toastStateStore.state.toasts, [
            .moveTo(destinationName: destination.name.humanReadable.string)
        ])
    }

    private func verifyGeneralAction(action: GeneralActions) {
        let sut = sut(id: 42, type: .message, title: .notUsed)

        sut.handle(action: .generalActionTapped(action))

        XCTAssertEqual(toastStateStore.state.toasts, [.comingSoon])
    }

    private func sut(id: UInt64, type: MailboxItemType, title: String) -> MailboxItemActionSheetStateStore {
        MailboxItemActionSheetStateStore(
            input: .init(id: .init(value: id), type: type, title: title),
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
            generalActions: generalActionsSpy.testingInstance,
            mailUserSession: .dummy,
            toastStateStore: toastStateStore,
            navigation: { navigation in self.spiedNavigation.append(navigation) }
        )
    }

}

private extension MoveToAction {

    var destination: MoveToSystemFolderLocation? {
        switch self {
        case .moveToSystemFolder(let label), .notSpam(let label):
            return label
        case .moveTo, .permanentDelete:
            return nil
        }
    }

}

private extension MailboxItemActionSheetState {

    func alertAction(for string: LocalizedStringResource) throws -> AlertAction {
        try XCTUnwrap(alert?.actions.findFirst(for: string, by: \.title))
    }

}
