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
@testable import InboxCoreUI
import InboxCore
import InboxTesting
import proton_app_uniffi
import XCTest

class LabelAsSheetModelTests: BaseTestCase {
    var invokedAvailableActionsWithMessagesIDs: [ID]!
    var invokedAvailableActionsWithConversationIDs: [ID]!
    var invokedDismissCount: Int!
    var stubbedLabelAsActions: [LabelAsAction]!
    var stubbedLabelAsOutput: LabelAsOutput!

    private var toastStateStore: ToastStateStore!
    private var invokedLabelMessage: [LabelAsExecutedWithData]!
    private var invokedLabelConversation: [LabelAsExecutedWithData]!

    override func setUp() {
        super.setUp()

        stubbedLabelAsOutput = .init(inputLabelIsEmpty: false, undo: UndoSpy(noPointer: .init()))
        toastStateStore = .init(initialState: .initial)
        invokedAvailableActionsWithMessagesIDs = []
        invokedAvailableActionsWithConversationIDs = []
        invokedLabelMessage = []
        invokedLabelConversation = []
        invokedDismissCount = 0
    }

    override func tearDown() {
        toastStateStore = nil
        invokedAvailableActionsWithMessagesIDs = nil
        invokedAvailableActionsWithConversationIDs = nil
        invokedLabelMessage = nil
        invokedLabelConversation = nil
        invokedDismissCount = nil
        stubbedLabelAsActions = nil
        stubbedLabelAsOutput = nil

        super.tearDown()
    }

    func testState_WhenMailboxTypeIsMessageAndLabelsAreLoaded_ItReturnsLabelActions() {
        stubbedLabelAsActions = LabelAsSheetPreviewProvider.testLabels()
        let messageIDs: [ID] = [.init(value: 7), .init(value: 88)]
        let sut = sut(ids: messageIDs, type: .message)

        sut.handle(action: .viewAppear)

        XCTAssertEqual(invokedAvailableActionsWithMessagesIDs, messageIDs)
        XCTAssertEqual(invokedAvailableActionsWithConversationIDs, [])
        XCTAssertEqual(
            sut.state,
            .init(
                labels: LabelAsSheetPreviewProvider.testLabels().map(\.displayModel),
                shouldArchive: false,
                createFolderLabelPresented: false
            )
        )
    }

    func testNavigation_WhenDoneButtonIsTapped_ItReturnsCorrectValue() {
        let sut = sut(ids: [.init(value: 7), .init(value: 88)], type: .message)
        sut.handle(action: .saveButtonTapped)

        XCTAssertEqual(invokedDismissCount, 1)
    }

    func testState_WhenMailboxTypeIsConversationAndArchiveToggleIsTapped_ItReturnsCorrectState() {
        stubbedLabelAsActions = LabelAsSheetPreviewProvider.testLabels()
        let conversationIDs: [ID] = [.init(value: 1), .init(value: 3)]
        let sut = sut(ids: conversationIDs, type: .conversation)

        sut.handle(action: .viewAppear)

        XCTAssertEqual(invokedAvailableActionsWithMessagesIDs, [])
        XCTAssertEqual(invokedAvailableActionsWithConversationIDs, conversationIDs)
        XCTAssertEqual(
            sut.state,
            .init(
                labels: LabelAsSheetPreviewProvider.testLabels().map(\.displayModel),
                shouldArchive: false,
                createFolderLabelPresented: false
            )
        )

        sut.handle(action: .toggleSwitch)

        XCTAssertEqual(
            sut.state,
            .init(
                labels: LabelAsSheetPreviewProvider.testLabels().map(\.displayModel),
                shouldArchive: true,
                createFolderLabelPresented: false
            )
        )
    }

    func testState_WhenCreateLabelButtonIsTapped_ItReturnsCorrectState() {
        let sut = sut(ids: [], type: .conversation)

        sut.handle(action: .createLabelButtonTapped)

        XCTAssertTrue(sut.state.createFolderLabelPresented)
    }

    func testState_WhenLabelActionsSelectionIsChanged_ItReturnsCorrectState() {
        stubbedLabelAsActions = [IsSelected.partial, .selected, .unselected]
            .enumerated()
            .map { index, status in
                .testData(id: .init(value: UInt64(index)), isSelected: status)
            }
        let firstLabel = stubbedLabelAsActions[0]
        let secondLabel = stubbedLabelAsActions[1]
        let thirdLabel = stubbedLabelAsActions[2]

        let sut = sut(ids: [], type: .conversation)

        sut.handle(action: .viewAppear)

        XCTAssertEqual(
            sut.state,
            .init(
                labels: [firstLabel, secondLabel, thirdLabel].map(\.displayModel),
                shouldArchive: false,
                createFolderLabelPresented: false
            )
        )

        sut.handle(action: .selected(firstLabel.displayModel))
        sut.handle(action: .selected(secondLabel.displayModel))
        sut.handle(action: .selected(thirdLabel.displayModel))

        XCTAssertEqual(
            sut.state,
            .init(
                labels: [
                    firstLabel.copy(isSelected: .unselected).displayModel,
                    secondLabel.copy(isSelected: .unselected).displayModel,
                    thirdLabel.copy(isSelected: .selected).displayModel,
                ],
                shouldArchive: false,
                createFolderLabelPresented: false
            )
        )
    }

    func testLabelAsAction_WhenArchiveNotSelected_ItDoesNotShowUndoToast() throws {
        try testLabelAsWithArchiveDisabled(itemType: .message, spyToVerify: { invokedLabelMessage })
    }

    func testLabelAsAction_WhenOneLabelIsSelectedAndOtherPartiallySelected_ItLabelsMessage() throws {
        try testLabelAsWithArchiveEnabled(
            itemType: .message,
            spyToVerify: { invokedLabelMessage },
            expectToastMessage: L10n.Toast.messageMovedTo(count: 2)
        )
    }

    func testLabelAsAction_WhenOneLabelIsSelectedAndOtherPartiallySelected_ItLabelsConversation() throws {
        try testLabelAsWithArchiveEnabled(
            itemType: .conversation,
            spyToVerify: { invokedLabelConversation },
            expectToastMessage: L10n.Toast.conversationMovedTo(count: 2)
        )
    }

    // MARK: - Private

    private func sut(ids: [ID], type: MailboxItemType) -> LabelAsSheetModel {
        LabelAsSheetModel(
            input: .init(sheetType: .labelAs, ids: ids, mailboxItem: type.mailboxItem),
            mailbox: .init(noPointer: .init()),
            availableLabelAsActions: .init(
                message: { _, ids in
                    self.invokedAvailableActionsWithMessagesIDs = ids
                    return .ok(self.stubbedLabelAsActions)
                },
                conversation: { _, ids in
                    self.invokedAvailableActionsWithConversationIDs = ids
                    return .ok(self.stubbedLabelAsActions)
                }
            ),
            labelAsActions: .init(
                labelMessagesAs: { _, ids, selectedLabelIDs, partiallySelectedLabelIDs, archive in
                    self.invokedLabelMessage.append(
                        .init(
                            itemsIDs: ids,
                            selectedLabelIDs: selectedLabelIDs,
                            partiallySelectedLabelIDs: partiallySelectedLabelIDs,
                            archive: archive
                        ))

                    return .ok(self.stubbedLabelAsOutput)
                },
                labelConversationsAs: { mailbox, ids, selectedLabelIDs, partiallySelectedLabelIDs, archive in
                    self.invokedLabelConversation.append(
                        .init(
                            itemsIDs: ids,
                            selectedLabelIDs: selectedLabelIDs,
                            partiallySelectedLabelIDs: partiallySelectedLabelIDs,
                            archive: archive
                        ))

                    return .ok(self.stubbedLabelAsOutput)
                }
            ),
            toastStateStore: toastStateStore,
            mailUserSession: .dummy,
            dismiss: { self.invokedDismissCount += 1 }
        )
    }

    private func testLabelAsWithArchiveDisabled(
        itemType: MailboxItemType,
        spyToVerify: () -> [LabelAsExecutedWithData]
    ) throws {
        let undoSpy = UndoSpy(noPointer: .init())
        let selectedLabelID: ID = .init(value: 2)
        let partiallySelectedLabelID: ID = .init(value: 4)
        stubbedLabelAsActions = [
            .testData(id: selectedLabelID, isSelected: .selected),
            .testData(id: partiallySelectedLabelID, isSelected: .partial),
            .testData(id: .random(), isSelected: .unselected),
        ]
        stubbedLabelAsOutput = .init(inputLabelIsEmpty: false, undo: undoSpy)

        let itemsIDs: [ID] = [.init(value: 1), .init(value: 3)]
        let sut = sut(ids: itemsIDs, type: itemType)

        sut.handle(action: .viewAppear)
        sut.handle(action: .saveButtonTapped)

        XCTAssertEqual(
            spyToVerify(),
            [
                .init(
                    itemsIDs: itemsIDs,
                    selectedLabelIDs: [selectedLabelID],
                    partiallySelectedLabelIDs: [partiallySelectedLabelID],
                    archive: false
                )
            ]
        )
        XCTAssertEqual(invokedDismissCount, 1)

        XCTAssertEqual(toastStateStore.state.toasts.count, 0)
        XCTAssertEqual(undoSpy.undoCallsCount, 0)
    }

    private func testLabelAsWithArchiveEnabled(
        itemType: MailboxItemType,
        spyToVerify: () -> [LabelAsExecutedWithData],
        expectToastMessage: LocalizedStringResource
    ) throws {
        let undoSpy = UndoSpy(noPointer: .init())
        let selectedLabelID: ID = .init(value: 2)
        let partiallySelectedLabelID: ID = .init(value: 4)
        stubbedLabelAsActions = [
            .testData(id: selectedLabelID, isSelected: .selected),
            .testData(id: partiallySelectedLabelID, isSelected: .partial),
            .testData(id: .random(), isSelected: .unselected),
        ]
        stubbedLabelAsOutput = .init(inputLabelIsEmpty: false, undo: undoSpy)

        let itemsIDs: [ID] = [.init(value: 1), .init(value: 3)]
        let sut = sut(ids: itemsIDs, type: itemType)

        sut.handle(action: .viewAppear)
        sut.handle(action: .toggleSwitch)
        sut.handle(action: .saveButtonTapped)

        XCTAssertEqual(
            spyToVerify(),
            [
                .init(
                    itemsIDs: itemsIDs,
                    selectedLabelIDs: [selectedLabelID],
                    partiallySelectedLabelIDs: [partiallySelectedLabelID],
                    archive: true
                )
            ]
        )
        XCTAssertEqual(invokedDismissCount, 1)

        XCTAssertEqual(toastStateStore.state.toasts.count, 1)

        let toastToVerify: Toast = try XCTUnwrap(toastStateStore.state.toasts.last)

        XCTAssertEqual(toastToVerify.message, expectToastMessage.string)

        toastToVerify.simulateUndoAction()

        XCTAssertEqual(undoSpy.undoCallsCount, 1)
        XCTAssertEqual(toastStateStore.state.toasts.isEmpty, true)
    }

    private struct LabelAsExecutedWithData: Equatable {
        let itemsIDs: [ID]
        let selectedLabelIDs: [ID]
        let partiallySelectedLabelIDs: [ID]
        let archive: Bool
    }
}

private extension LabelAsAction {
    func copy(isSelected: IsSelected) -> Self {
        .init(labelId: labelId, name: name, color: color, isSelected: isSelected)
    }

    static func testData(id: ID, isSelected: IsSelected) -> Self {
        .init(labelId: id, name: .notUsed, color: .init(value: .notUsed), isSelected: isSelected)
    }
}
