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
final class MoveToSheetStateStoreTests {
    var invokedAvailableActionsWithMessagesIDs: [ID]!
    var invokedAvailableActionsWithConversationIDs: [ID]!
    var invokedNavigation: [MoveToSheetNavigation]!
    var toastStateStore: ToastStateStore!
    var moveToActionsSpy: MoveToActionsSpy!

    init() {
        invokedAvailableActionsWithMessagesIDs = []
        invokedAvailableActionsWithConversationIDs = []
        invokedNavigation = []
        toastStateStore = .init(initialState: .initial)
        moveToActionsSpy = .init()
    }

    @Test
    func state_WhenMailboxTypeIsMessageAndViewAppear_ItReturnsMoveToActions() async {
        let ids: [ID] = [.init(value: 777), .init(value: 111)]
        let sut = sut(input: .init(sheetType: .moveTo, ids: ids, mailboxItem: .message(isLastMessageInCurrentLocation: false)))

        await sut.handle(action: .viewAppear)

        #expect(invokedAvailableActionsWithMessagesIDs == ids)
        #expect(invokedAvailableActionsWithConversationIDs == [])
    }

    @Test
    func state_WhenMailboxTypeIsConversationAndViewAppear_ItReturnsMoveToActions() async {
        let ids: [ID] = [.init(value: 777), .init(value: 111)]
        let sut = sut(input: .init(sheetType: .moveTo, ids: ids, mailboxItem: .conversation))

        await sut.handle(action: .viewAppear)

        #expect(invokedAvailableActionsWithMessagesIDs == [])
        #expect(invokedAvailableActionsWithConversationIDs == ids)
    }

    @Test
    func state_WhenCreateFolderActionIsHandled_ItPresentsCreateFolderLabelModal() async {
        let sut = sut(input: .init(sheetType: .moveTo, ids: [], mailboxItem: .message(isLastMessageInCurrentLocation: false)))

        await sut.handle(action: .createFolderTapped)

        #expect(sut.state.createFolderLabelPresented == true)
    }

    @Test
    func action_WhenCustomFolderIsTapped_ItMovesConversationToCustomFolder() async {
        let sut = sut(input: .init(sheetType: .moveTo, ids: [.init(value: 2)], mailboxItem: .conversation))

        await sut.handle(action: .customFolderTapped(.init(id: .init(value: 1), name: "Private")))

        #expect(
            moveToActionsSpy.invokedMoveToConversation == [
                .init(destinationID: .init(value: 1), itemsIDs: [.init(value: 2)])
            ])
        #expect(
            toastStateStore.state.toasts == [
                .moveTo(id: UUID(), destinationName: "Private", undoAction: .none)
            ]
        )
        #expect(invokedNavigation == [.dismissAndGoBack])
    }

    @Test
    func action_WhenInboxIsTapped_ItMovesMessageToInbox() async {
        let sut = sut(input: .init(sheetType: .moveTo, ids: [.init(value: 1)], mailboxItem: .message(isLastMessageInCurrentLocation: false)))

        await sut.handle(action: .systemFolderTapped(.init(id: .init(value: 10), label: .inbox)))

        #expect(
            moveToActionsSpy.invokedMoveToMessage == [
                .init(destinationID: .init(value: 10), itemsIDs: [.init(value: 1)])
            ])
        #expect(
            toastStateStore.state.toasts == [
                .moveTo(id: UUID(), destinationName: "Inbox", undoAction: .none)
            ]
        )
        #expect(invokedNavigation == [.dismiss])
    }

    @Test
    func action_WhenInboxIsTappedUndoIsAvailableAndTapped_ItTriggersUndoAndDismissesToast() async throws {
        let undoSpy = UndoSpy(noPointer: .init())
        moveToActionsSpy.stubbedMoveMessagesToOkResult = undoSpy

        let sut = sut(
            input: .init(
                sheetType: .moveTo,
                ids: [.init(value: 1)],
                mailboxItem: .message(isLastMessageInCurrentLocation: false)
            )
        )

        await sut.handle(action: .systemFolderTapped(.init(id: .init(value: 10), label: .inbox)))

        #expect(
            moveToActionsSpy.invokedMoveToMessage == [
                .init(destinationID: .init(value: 10), itemsIDs: [.init(value: 1)])
            ])
        #expect(
            toastStateStore.state.toasts == [
                .moveTo(id: UUID(), destinationName: "Inbox", undoAction: {})
            ]
        )
        #expect(invokedNavigation == [.dismiss])

        let toastToVeriy: Toast = try #require(toastStateStore.state.toasts.last)

        await toastToVeriy.simulateUndoAction()

        #expect(undoSpy.undoCallsCount == 1)
        #expect(toastStateStore.state.toasts.isEmpty == true)
    }

    @Test
    func action_WhenItsStandaloneMessageInConveration_WhenInboxIsTapped_ItMovesMessageToInbox() async {
        let sut = sut(input: .init(sheetType: .moveTo, ids: [.init(value: 1)], mailboxItem: .message(isLastMessageInCurrentLocation: true)))

        await sut.handle(action: .systemFolderTapped(.init(id: .init(value: 10), label: .inbox)))

        #expect(invokedNavigation == [.dismissAndGoBack])
    }

    // MARK: - Private

    private func sut(input: ActionSheetInput) -> MoveToSheetStateStore {
        .init(
            state: .initial,
            input: input,
            mailbox: .init(noPointer: .init()),
            availableMoveToActions: .init(
                message: { _, ids in
                    self.invokedAvailableActionsWithMessagesIDs = ids
                    return .ok([])
                },
                conversation: { _, ids in
                    self.invokedAvailableActionsWithConversationIDs = ids
                    return .ok([])
                }
            ),
            toastStateStore: toastStateStore,
            moveToActions: moveToActionsSpy.testingInstance,
            navigation: { self.invokedNavigation.append($0) },
            mailUserSession: .dummy
        )
    }
}
