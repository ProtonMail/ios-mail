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

class MoveToSheetStateStoreTests: BaseTestCase {

    var invokedAvailableActionsWithMessagesIDs: [ID]!
    var invokedAvailableActionsWithConversationIDs: [ID]!
    var invokedNavigation: [MoveToSheetNavigation]!
    var toastStateStore: ToastStateStore!
    var moveToActionsSpy: MoveToActionsSpy!

    override func setUp() {
        super.setUp()
        invokedAvailableActionsWithMessagesIDs = []
        invokedAvailableActionsWithConversationIDs = []
        invokedNavigation = []
        toastStateStore = .init(initialState: .initial)
        moveToActionsSpy = .init()
    }

    override func tearDown() {
        invokedAvailableActionsWithMessagesIDs = nil
        invokedAvailableActionsWithConversationIDs = nil
        invokedNavigation = nil
        toastStateStore = nil
        moveToActionsSpy = nil

        super.tearDown()
    }

    func testState_WhenMailboxTypeIsMessageAndViewAppear_ItReturnsMoveToActions() {
        let ids: [ID] = [.init(value: 777), .init(value: 111)]
        let sut = sut(input: .init(sheetType: .moveTo, ids: ids, type: .message(isLastMessageInCurrentLocation: false)))

        sut.handle(action: .viewAppear)

        XCTAssertEqual(invokedAvailableActionsWithMessagesIDs, ids)
        XCTAssertEqual(invokedAvailableActionsWithConversationIDs, [])
    }

    func testState_WhenMailboxTypeIsConversationAndViewAppear_ItReturnsMoveToActions() {
        let ids: [ID] = [.init(value: 777), .init(value: 111)]
        let sut = sut(input: .init(sheetType: .moveTo, ids: ids, type: .conversation))

        sut.handle(action: .viewAppear)

        XCTAssertEqual(invokedAvailableActionsWithMessagesIDs, [])
        XCTAssertEqual(invokedAvailableActionsWithConversationIDs, ids)
    }

    func testState_WhenCreateFolderActionIsHandled_ItPresentsCreateFolderLabelModal() {
        let sut = sut(input: .init(sheetType: .moveTo, ids: [], type: .message(isLastMessageInCurrentLocation: false)))

        sut.handle(action: .createFolderTapped)

        XCTAssertTrue(sut.state.createFolderLabelPresented)
    }

    func testAction_WhenCustomFolderIsTapped_ItMovesConversationToCustomFolder() {
        let sut = sut(input: .init(sheetType: .moveTo, ids: [.init(value: 2)], type: .conversation))

        sut.handle(action: .customFolderTapped(.init(id: .init(value: 1), name: "Private")))

        XCTAssertEqual(
            moveToActionsSpy.invokedMoveToConversation,
            [
                .init(destinationID: .init(value: 1), itemsIDs: [.init(value: 2)])
            ])
        XCTAssertEqual(
            toastStateStore.state.toasts,
            [
                .moveTo(id: UUID(), destinationName: "Private", undoAction: .none)
            ]
        )
        XCTAssertEqual(invokedNavigation, [.dismissAndGoBack])
    }

    func testAction_WhenInboxIsTapped_ItMovesMessageToInbox() {
        let sut = sut(input: .init(sheetType: .moveTo, ids: [.init(value: 1)], type: .message(isLastMessageInCurrentLocation: false)))

        sut.handle(action: .systemFolderTapped(.init(id: .init(value: 10), label: .inbox)))

        XCTAssertEqual(
            moveToActionsSpy.invokedMoveToMessage,
            [
                .init(destinationID: .init(value: 10), itemsIDs: [.init(value: 1)])
            ])
        XCTAssertEqual(
            toastStateStore.state.toasts,
            [
                .moveTo(id: UUID(), destinationName: "Inbox", undoAction: .none)
            ]
        )
        XCTAssertEqual(invokedNavigation, [.dismiss])
    }

    func testAction_WhenInboxIsTappedUndoIsAvailableAndTapped_ItTriggersUndoAndDismissesToast() throws {
        let undoSpy = UndoSpy(noPointer: .init())
        moveToActionsSpy.stubbedMoveMessagesToOkResult = undoSpy

        let sut = sut(
            input: .init(
                sheetType: .moveTo,
                ids: [.init(value: 1)],
                type: .message(isLastMessageInCurrentLocation: false)
            )
        )

        sut.handle(action: .systemFolderTapped(.init(id: .init(value: 10), label: .inbox)))

        XCTAssertEqual(
            moveToActionsSpy.invokedMoveToMessage,
            [
                .init(destinationID: .init(value: 10), itemsIDs: [.init(value: 1)])
            ])
        XCTAssertEqual(
            toastStateStore.state.toasts,
            [
                .moveTo(id: UUID(), destinationName: "Inbox", undoAction: {})
            ]
        )
        XCTAssertEqual(invokedNavigation, [.dismiss])

        let toastToVeriy: Toast = try XCTUnwrap(toastStateStore.state.toasts.last)

        toastToVeriy.simulateUndoAction()

        XCTAssertEqual(undoSpy.undoCallsCount, 1)
        XCTAssertEqual(toastStateStore.state.toasts.isEmpty, true)
    }

    func testAction_WhenItsStandaloneMessageInConveration_WhenInboxIsTapped_ItMovesMessageToInbox() {
        let sut = sut(input: .init(sheetType: .moveTo, ids: [.init(value: 1)], type: .message(isLastMessageInCurrentLocation: true)))

        sut.handle(action: .systemFolderTapped(.init(id: .init(value: 10), label: .inbox)))

        XCTAssertEqual(invokedNavigation, [.dismissAndGoBack])
    }

    // MARK: - Private

    private func sut(input: ActionSheetInput) -> MoveToSheetStateStore {
        .init(
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
