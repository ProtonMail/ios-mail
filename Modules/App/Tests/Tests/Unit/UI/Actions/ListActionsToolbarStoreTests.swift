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

import InboxCoreUI
import InboxTesting
import ProtonUIFoundations
import Testing
import proton_app_uniffi

@testable import ProtonMail

@MainActor
class ListActionsToolbarStoreTests {
    var sut: ListActionsToolbarStore!
    var invokedAvailableMessageActionsWithIDs: [[ID]]!
    var stubbedAvailableMessageActions: AllListActions!
    var invokedAvailableConversationActionsWithIDs: [[ID]]!
    var stubbedAvailableConversationActions: AllListActions!
    var starActionPerformerActionsSpy: StarActionPerformerActionsSpy!
    var readActionPerformerActionsSpy: ReadActionPerformerActionsSpy!
    var deleteActionsSpy: DeleteActionsSpy!
    var moveToActionsSpy: MoveToActionsSpy!
    var toastStateStore: ToastStateStore!

    init() {
        invokedAvailableMessageActionsWithIDs = []
        stubbedAvailableMessageActions = .testData
        invokedAvailableConversationActionsWithIDs = []
        starActionPerformerActionsSpy = .init()
        readActionPerformerActionsSpy = .init()
        deleteActionsSpy = .init()
        moveToActionsSpy = .init()
        toastStateStore = .init(initialState: .initial)
    }

    @Test
    func state_WhenListItemsSelectionIsUpdatedInMessageMode_ItReturnsCorrectState() async {
        let viewMode = ViewMode.messages
        sut = makeSUT(viewMode: viewMode)
        stubbedAvailableMessageActions = .init(
            hiddenListActions: [.labelAs, .markRead],
            visibleListActions: [.notSpam(.testInbox)]
        )

        let ids: [ID] = [.init(value: 11)]

        await sut.handle(action: .listItemsSelectionUpdated(ids: ids, itemType: viewMode.itemType))

        #expect(invokedAvailableMessageActionsWithIDs.count == 1)
        #expect(invokedAvailableConversationActionsWithIDs.count == 0)
        #expect(invokedAvailableMessageActionsWithIDs.first == ids)
        #expect(
            sut.state
                == .init(
                    bottomBarActions: [.notSpam(.testInbox)],
                    moreSheetOnlyActions: [.labelAs, .markRead],
                    isSnoozeSheetPresented: false,
                    isEditToolbarSheetPresented: false
                ))
    }

    @Test
    func state_WhenListItemsSelectionIsUpdatedInConversationModel_ItReturnsCorrectState() async {
        let viewMode = ViewMode.conversations
        sut = makeSUT(viewMode: viewMode)
        stubbedAvailableConversationActions = .init(
            hiddenListActions: [.notSpam(.testInbox), .permanentDelete],
            visibleListActions: [.more]
        )
        let ids: [ID] = [.init(value: 22)]

        await sut.handle(action: .listItemsSelectionUpdated(ids: ids, itemType: viewMode.itemType))

        #expect(invokedAvailableMessageActionsWithIDs.count == 0)
        #expect(invokedAvailableConversationActionsWithIDs.count == 1)
        #expect(invokedAvailableConversationActionsWithIDs.first == ids)
        #expect(
            sut.state
                == .init(
                    bottomBarActions: [.more],
                    moreSheetOnlyActions: [.notSpam(.testInbox), .permanentDelete],
                    isSnoozeSheetPresented: false,
                    isEditToolbarSheetPresented: false
                ))
    }

    @Test
    func state_WhenEditToolbarActionIsSelected_ItHasCorrectPresentationStatus() async {
        sut = makeSUT(viewMode: .messages)

        await sut.handle(action: .editToolbarTapped)

        #expect(sut.state.isEditToolbarSheetPresented == true)
    }

    @Test
    func state_WhenListItemsSelectionIsUpdatedWithNoSelection_ItReturnsCorrectState() async {
        let viewMode = ViewMode.messages
        sut = makeSUT(viewMode: viewMode)

        await sut.handle(action: .listItemsSelectionUpdated(ids: [], itemType: viewMode.itemType))

        #expect(invokedAvailableMessageActionsWithIDs.count == 0)
    }

    @Test
    func state_WhenMoveToActionIsSelectedAndThenMoveToSheetIsDismissed_ItReturnsCorrectState() async {
        let viewMode = ViewMode.messages
        sut = makeSUT(viewMode: viewMode)

        #expect(sut.state.moveToSheetPresented == nil)

        await sut.handle(action: .actionSelected(.moveTo, ids: [.init(value: 7)], itemType: viewMode.itemType))

        #expect(
            sut.state.moveToSheetPresented == .init(sheetType: .moveTo, ids: [.init(value: 7)], mailboxItem: .message(isLastMessageInCurrentLocation: false))
        )

        await sut.handle(action: .dismissMoveToSheet)

        #expect(sut.state.moveToSheetPresented == nil)
    }

    @Test
    func state_WhenLabelAsActionIsSelectedAndThenLabelAsSheetIsDismissed_ItReturnsCorrectState() async {
        let viewMode = ViewMode.conversations
        sut = makeSUT(viewMode: viewMode)
        let ids: [ID] = [.init(value: 8)]

        #expect(sut.state.labelAsSheetPresented == nil)

        await sut.handle(action: .actionSelected(.labelAs, ids: ids, itemType: .conversation))

        #expect(sut.state.labelAsSheetPresented == .init(sheetType: .labelAs, ids: ids, mailboxItem: viewMode.itemType.mailboxItem))

        await sut.handle(action: .dismissLabelAsSheet)

        #expect(sut.state.labelAsSheetPresented == nil)
    }

    @Test
    func state_WhenLabelAsActionOnMoreSheetIsSelected_ItReturnsCorrectState() async {
        let viewMode = ViewMode.messages
        sut = makeSUT(viewMode: viewMode)
        let ids: [ID] = [.init(value: 7)]

        await sut.handle(action: .moreSheetAction(.labelAs, ids: ids, itemType: viewMode.itemType))

        #expect(
            sut.state.labelAsSheetPresented == .init(sheetType: .labelAs, ids: ids, mailboxItem: .message(isLastMessageInCurrentLocation: false))
        )
    }

    @Test
    func state_WhenStarActionIsApplied_ItStarsCorrectMessages() async {
        let viewMode = ViewMode.messages
        sut = makeSUT(viewMode: viewMode)
        let ids: [ID] = [.init(value: 7), .init(value: 77)]

        await sut.handle(action: .actionSelected(.star, ids: ids, itemType: viewMode.itemType))

        #expect(starActionPerformerActionsSpy.invokedStarMessage == ids)
    }

    @Test
    func state_WhenUnstarActionIsAppliedFromMoreSheet_ItUnstarsCorrectMessage() async {
        let viewMode = ViewMode.messages
        sut = makeSUT(viewMode: viewMode)
        let ids: [ID] = [.init(value: 7), .init(value: 77)]

        await sut.handle(action: .actionSelected(.more, ids: ids, itemType: viewMode.itemType))

        await sut.handle(action: .moreSheetAction(.unstar, ids: ids, itemType: viewMode.itemType))
        #expect(starActionPerformerActionsSpy.invokedUnstarMessage == ids)
    }

    @Test
    func state_WhenReadActionIsApplied_ItMarksMessageAsRead() async {
        let viewMode = ViewMode.messages
        sut = makeSUT(viewMode: viewMode)
        let ids: [ID] = [.init(value: 7), .init(value: 77)]

        await sut.handle(action: .actionSelected(.markRead, ids: ids, itemType: viewMode.itemType))

        #expect(readActionPerformerActionsSpy.markMessageAsReadInvoked == ids)
    }

    @Test
    func state_WhenUnreadActionIsApplied_ItMarksConversationAsUnread() async {
        let viewMode = ViewMode.conversations
        sut = makeSUT(viewMode: viewMode)
        let ids: [ID] = [.init(value: 7), .init(value: 77)]

        await sut.handle(action: .actionSelected(.markUnread, ids: ids, itemType: viewMode.itemType))

        #expect(readActionPerformerActionsSpy.markConversationAsUnreadInvoked == ids)
    }

    @Test
    func action_WhenDeleteActionIsApplied_ItDeletesMessage() async {
        let ids: [ID] = [.init(value: 7), .init(value: 77)]
        let viewMode = ViewMode.messages
        sut = makeSUT(viewMode: viewMode)

        await sut.handle(action: .actionSelected(.permanentDelete, ids: ids, itemType: viewMode.itemType))

        #expect(sut.state.deleteConfirmationAlert == .deleteConfirmation(itemsCount: ids.count, action: { _ in }))

        await sut.handle(action: .alertActionTapped(.delete, ids: ids, itemType: viewMode.itemType))

        #expect(sut.state.deleteConfirmationAlert == nil)
        #expect(deleteActionsSpy.deletedMessagesWithIDs == ids)
        #expect(toastStateStore.state.toasts == [.deleted()])
    }

    @Test
    func action_WhenMoveToInboxIsTapped_ItMovesMessage() async {
        let ids: [ID] = [.init(value: 7), .init(value: 77)]
        let systemFolder = MovableSystemFolderAction.testInbox
        let viewMode = ViewMode.messages
        sut = makeSUT(viewMode: viewMode)

        await sut.handle(action: .actionSelected(.moveToSystemFolder(systemFolder), ids: ids, itemType: viewMode.itemType))

        #expect(
            toastStateStore.state.toasts == [.moveTo(id: UUID(), destinationName: systemFolder.name.displayData.title.string, undoAction: .none)]
        )
        #expect(
            moveToActionsSpy.invokedMoveToMessage == [.init(destinationID: systemFolder.localId, itemsIDs: ids)]
        )
    }

    @Test
    func action_WhenMoveToInboxIsTappedUndoIsAvailbleAndTapped_ItTriggersUndoAndDismissesToast() async throws {
        let ids: [ID] = [.init(value: 7), .init(value: 77)]
        let systemFolder = MovableSystemFolderAction.testInbox
        let undoSpy = UndoSpy(noPointer: .init())
        let viewMode = ViewMode.messages
        moveToActionsSpy.stubbedMoveMessagesToOkResult = undoSpy
        sut = makeSUT(viewMode: viewMode)

        await sut.handle(action: .actionSelected(.moveToSystemFolder(systemFolder), ids: ids, itemType: viewMode.itemType))

        #expect(
            toastStateStore.state.toasts == [.moveTo(id: UUID(), destinationName: systemFolder.name.displayData.title.string, undoAction: {})]
        )
        #expect(
            moveToActionsSpy.invokedMoveToMessage == [.init(destinationID: systemFolder.localId, itemsIDs: ids)]
        )

        let toastToVeriy: Toast = try #require(toastStateStore.state.toasts.last)

        await toastToVeriy.simulateUndoAction()

        #expect(undoSpy.undoCallsCount == 1)
        #expect(toastStateStore.state.toasts.isEmpty == true)
    }

    @Test
    func snoozeActionIsTapped_ItOpensSnoozeSheet() async {
        let viewMode = ViewMode.conversations
        let sut = makeSUT(viewMode: viewMode)

        await sut.handle(action: .actionSelected(.snooze, ids: [.init(value: 7)], itemType: viewMode.itemType))

        #expect(sut.state.isSnoozeSheetPresented == true)
    }

    // MARK: - Private

    private func makeSUT(viewMode: ViewMode) -> ListActionsToolbarStore {
        ListActionsToolbarStore(
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
            mailUserSession: .dummy,
            mailbox: MailboxStub(viewMode: viewMode),
            toastStateStore: toastStateStore
        )
    }
}

private extension AllListActions {
    static var testData: Self {
        .init(
            hiddenListActions: [
                .notSpam(.testInbox),
                .permanentDelete,
                .moveToSystemFolder(.init(localId: .init(value: 7), name: .archive)),
            ],
            visibleListActions: [.markRead, .star, .moveTo, .labelAs, .more]
        )
    }
}

extension MovableSystemFolderAction {
    static var testInbox: Self {
        .init(localId: .init(value: 999), name: .inbox)
    }
}
