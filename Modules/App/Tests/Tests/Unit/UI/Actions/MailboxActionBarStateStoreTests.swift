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

class MailboxActionBarStateStoreTests: BaseTestCase {

    var sut: MailboxActionBarStateStore!
    var invokedAvailableMessageActionsWithIDs: [[ID]]!
    var stubbedAvailableMessageActions: AllBottomBarMessageActions!
    var invokedAvailableConversationActionsWithIDs: [[ID]]!
    var stubbedAvailableConversationActions: AllBottomBarMessageActions!
    var starActionPerformerActionsSpy: StarActionPerformerActionsSpy!
    var readActionPerformerActionsSpy: ReadActionPerformerActionsSpy!
    var deleteActionsSpy: DeleteActionsSpy!
    var moveToActionsSpy: MoveToActionsSpy!
    var toastStateStore: ToastStateStore!

    override func setUp() {
        super.setUp()
        invokedAvailableMessageActionsWithIDs = []
        stubbedAvailableMessageActions = .testData
        invokedAvailableConversationActionsWithIDs = []
        starActionPerformerActionsSpy = .init()
        readActionPerformerActionsSpy = .init()
        deleteActionsSpy = .init()
        moveToActionsSpy = .init()
        toastStateStore = .init(initialState: .initial)
    }

    override func tearDown() {
        sut = nil
        invokedAvailableMessageActionsWithIDs = nil
        stubbedAvailableMessageActions = nil
        invokedAvailableConversationActionsWithIDs = nil
        starActionPerformerActionsSpy = nil
        readActionPerformerActionsSpy = nil
        deleteActionsSpy = nil
        moveToActionsSpy = nil
        toastStateStore = nil

        super.tearDown()
    }

    func testState_WhenMailboxItemsSelectionIsUpdatedInMessageMode_ItReturnsCorrectState() {
        sut = makeSUT(viewMode: .messages)
        stubbedAvailableMessageActions = .init(
            hiddenBottomBarActions: [.labelAs, .markRead],
            visibleBottomBarActions: [.notSpam(.testInbox)]
        )

        let ids: [ID] = [.init(value: 11)]

        sut.handle(action: .mailboxItemsSelectionUpdated(ids: ids))

        XCTAssertEqual(invokedAvailableMessageActionsWithIDs.count, 1)
        XCTAssertEqual(invokedAvailableConversationActionsWithIDs.count, 0)
        XCTAssertEqual(invokedAvailableMessageActionsWithIDs.first, ids)
        XCTAssertEqual(sut.state, .init(
            bottomBarActions: [.notSpam(.testInbox)],
            moreSheetOnlyActions: [.labelAs, .markRead]
        ))
    }

    func testState_WhenMailboxItemsSelectionIsUpdatedInConversationModel_ItReturnsCorrectState() {
        sut = makeSUT(viewMode: .conversations)
        stubbedAvailableConversationActions = .init(
            hiddenBottomBarActions: [.notSpam(.testInbox), .permanentDelete],
            visibleBottomBarActions: [.more]
        )
        let ids: [ID] = [.init(value: 22)]

        sut.handle(action: .mailboxItemsSelectionUpdated(ids: ids))

        XCTAssertEqual(invokedAvailableMessageActionsWithIDs.count, 0)
        XCTAssertEqual(invokedAvailableConversationActionsWithIDs.count, 1)
        XCTAssertEqual(invokedAvailableConversationActionsWithIDs.first, ids)
        XCTAssertEqual(sut.state, .init(
            bottomBarActions: [.more],
            moreSheetOnlyActions: [.notSpam(.testInbox), .permanentDelete]
        ))
    }

    func testState_WhenMailboxItemsSelectionIsUpdatedWithNoSelection_ItReturnsCorrectState() {
        sut = makeSUT(viewMode: .messages)

        sut.handle(action: .mailboxItemsSelectionUpdated(ids: []))

        XCTAssertEqual(invokedAvailableMessageActionsWithIDs.count, 0)
    }

    func testState_WhenMoveToActionIsSelectedAndThenMoveToSheetIsDismissed_ItReturnsCorrectState() {
        sut = makeSUT(viewMode: .messages)

        XCTAssertNil(sut.state.moveToSheetPresented)

        sut.handle(action: .actionSelected(.moveTo, ids: [.init(value: 7)]))

        XCTAssertEqual(
            sut.state.moveToSheetPresented,
            .init(sheetType: .moveTo, ids: [.init(value: 7)], type: .message(isStandaloneMessage: false))
        )

        sut.handle(action: .dismissMoveToSheet)

        XCTAssertNil(sut.state.moveToSheetPresented)
    }

    func testState_WhenLabelAsActionIsSelectedAndThenLabelAsSheetIsDismissed_ItReturnsCorrectState() {
        sut = makeSUT(viewMode: .conversations)
        let ids: [ID] = [.init(value: 8)]

        XCTAssertNil(sut.state.labelAsSheetPresented)

        sut.handle(action: .actionSelected(.labelAs, ids: ids))

        XCTAssertEqual(sut.state.labelAsSheetPresented, .init(sheetType: .labelAs, ids: ids, type: .conversation))

        sut.handle(action: .dismissLabelAsSheet)

        XCTAssertNil(sut.state.labelAsSheetPresented)
    }

    func testState_WhenMoreActionIsSelected_ItReturnsCorrectState() {
        sut = makeSUT(viewMode: .messages)
        let ids: [ID] = [.init(value: 9)]

        XCTAssertNil(sut.state.moreActionSheetPresented)

        sut.handle(action: .mailboxItemsSelectionUpdated(ids: ids))
        sut.handle(action: .actionSelected(.more, ids: ids))

        XCTAssertEqual(sut.state.moreActionSheetPresented, .init(
            selectedItemsIDs: [.init(value: 9)],
            bottomBarActions: [.markRead, .star, .moveTo, .labelAs],
            moreSheetOnlyActions: [
                .notSpam(.testInbox),
                .permanentDelete,
                .moveToSystemFolder(.init(localId: .init(value: 7), name: .archive))
            ]
        ))
    }

    func testState_WhenLabelAsActionOnMoreSheetIsSelected_ItReturnsCorrectState() {
        sut = makeSUT(viewMode: .messages)
        let ids: [ID] = [.init(value: 7)]

        sut.handle(action: .moreSheetAction(.labelAs, ids: ids))

        XCTAssertEqual(
            sut.state.labelAsSheetPresented,
            .init(sheetType: .labelAs, ids: ids, type: .message(isStandaloneMessage: false))
        )
    }

    func testState_WhenStarActionIsApplied_ItStarsCorrectMessages() {
        sut = makeSUT(viewMode: .messages)
        let ids: [ID] = [.init(value: 7), .init(value: 77)]

        sut.handle(action: .actionSelected(.star, ids: ids))

        XCTAssertEqual(starActionPerformerActionsSpy.invokedStarMessage, ids)
    }

    func testState_WhenUnstarActionIsAppliedFromMoreSheet_ItUnstarsCorrectMessage() {
        sut = makeSUT(viewMode: .messages)
        let ids: [ID] = [.init(value: 7), .init(value: 77)]

        sut.handle(action: .actionSelected(.more, ids: ids))
        XCTAssertNotNil(sut.state.moreActionSheetPresented)

        sut.handle(action: .moreSheetAction(.unstar, ids: ids))
        XCTAssertEqual(starActionPerformerActionsSpy.invokedUnstarMessage, ids)
    }

    func testState_WhenReadActionIsApplied_ItMarksMessageAsRead() {
        sut = makeSUT(viewMode: .messages)
        let ids: [ID] = [.init(value: 7), .init(value: 77)]

        sut.handle(action: .actionSelected(.markRead, ids: ids))

        XCTAssertEqual(readActionPerformerActionsSpy.markMessageAsReadInvoked, ids)
    }

    func testState_WhenUnreadActionIsApplied_ItMarksConversationAsUnread() {
        sut = makeSUT(viewMode: .conversations)
        let ids: [ID] = [.init(value: 7), .init(value: 77)]

        sut.handle(action: .actionSelected(.markUnread, ids: ids))

        XCTAssertEqual(readActionPerformerActionsSpy.markConversationAsUnreadInvoked, ids)
    }

    func testAction_WhenDeleteActionIsApplied_ItDeletesMessage() {
        let ids: [ID] = [.init(value: 7), .init(value: 77)]
        sut = makeSUT(viewMode: .messages)

        sut.handle(action: .actionSelected(.permanentDelete, ids: ids))

        XCTAssertEqual(sut.state.deleteConfirmationAlert, .deleteConfirmation(itemsCount: ids.count, action: { _ in }))

        sut.handle(action: .alertActionTapped(.delete, ids: ids))

        XCTAssertNil(sut.state.deleteConfirmationAlert)
        XCTAssertEqual(deleteActionsSpy.deletedMessagesWithIDs, ids)
        XCTAssertEqual(toastStateStore.state.toasts, [.deleted()])
    }

    func testAction_WhenMoveToInboxIsTapped_ItMovesMessage() {
        let ids: [ID] = [.init(value: 7), .init(value: 77)]
        let systemFolder = MoveToSystemFolderLocation.testInbox
        sut = makeSUT(viewMode: .messages)

        sut.handle(action: .actionSelected(.moveToSystemFolder(systemFolder), ids: ids))

        XCTAssertEqual(
            toastStateStore.state.toasts,
            [.moveTo(destinationName: systemFolder.name.humanReadable.string)]
        )
        XCTAssertEqual(
            moveToActionsSpy.invokedMoveToMessage,
            [.init(destinationID: systemFolder.localId, itemsIDs: ids)]
        )
    }

    // MARK: - Private

    private func makeSUT(viewMode: ViewMode) -> MailboxActionBarStateStore {
        MailboxActionBarStateStore(
            state: .initial,
            availableActions: .init(
                message: { _, ids in
                    self.invokedAvailableMessageActionsWithIDs.append(ids)

                    return .ok(self.stubbedAvailableMessageActions)
                },
                conversation: { _, ids in
                    self.invokedAvailableConversationActionsWithIDs.append(ids)

                    return .ok(self.stubbedAvailableConversationActions)
                }
            ),
            starActionPerformerActions: starActionPerformerActionsSpy.testingInstance,
            readActionPerformerActions: readActionPerformerActionsSpy.testingInstance,
            deleteActions: deleteActionsSpy.testingInstance,
            moveToActions: moveToActionsSpy.testingInstance,
            itemTypeForActionBar: viewMode.itemType,
            mailUserSession: .dummy,
            mailbox: MailboxStub(viewMode: viewMode),
            toastStateStore: toastStateStore
        )
    }

}
