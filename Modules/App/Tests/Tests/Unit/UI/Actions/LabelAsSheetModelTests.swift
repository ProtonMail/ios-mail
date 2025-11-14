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
@testable import ProtonUIFoundations
import InboxCore
import InboxTesting
import proton_app_uniffi
import ProtonUIFoundations
import Testing

@MainActor
final class LabelAsSheetModelTests {
    private var invokedAvailableActionsWithMessagesIDs: [ID] = []
    private var invokedAvailableActionsWithConversationIDs: [ID] = []
    private var invokedDismissCount = 0
    private var stubbedLabelAsActions: [LabelAsAction] = []
    private var stubbedLabelAsOutput: LabelAsOutput = .init(inputLabelIsEmpty: false, undo: UndoSpy(noPointer: .init()))

    private var toastStateStore = ToastStateStore(initialState: .initial)
    private var invokedLabelMessage: [LabelAsExecutedWithData] = []
    private var invokedLabelConversation: [LabelAsExecutedWithData] = []

    @Test
    func testState_WhenMailboxTypeIsMessageAndLabelsAreLoaded_ItReturnsLabelActions() async {
        stubbedLabelAsActions = LabelAsSheetPreviewProvider.testLabels()
        let messageIDs: [ID] = [.init(value: 7), .init(value: 88)]
        let sut = sut(ids: messageIDs, type: .message)

        await sut.handle(action: .viewAppear)

        #expect(invokedAvailableActionsWithMessagesIDs == messageIDs)
        #expect(invokedAvailableActionsWithConversationIDs == [])
        #expect(
            sut.state
                == .init(
                    labels: LabelAsSheetPreviewProvider.testLabels().map(\.displayModel),
                    shouldArchive: false,
                    createFolderLabelPresented: false
                )
        )
    }

    @Test
    func testNavigation_WhenDoneButtonIsTapped_ItReturnsCorrectValue() async {
        let sut = sut(ids: [.init(value: 7), .init(value: 88)], type: .message)
        await sut.handle(action: .saveButtonTapped)

        #expect(invokedDismissCount == 1)
    }

    @Test
    func testState_WhenMailboxTypeIsConversationAndArchiveToggleIsTapped_ItReturnsCorrectState() async {
        stubbedLabelAsActions = LabelAsSheetPreviewProvider.testLabels()
        let conversationIDs: [ID] = [.init(value: 1), .init(value: 3)]
        let sut = sut(ids: conversationIDs, type: .conversation)

        await sut.handle(action: .viewAppear)

        #expect(invokedAvailableActionsWithMessagesIDs == [])
        #expect(invokedAvailableActionsWithConversationIDs == conversationIDs)
        #expect(
            sut.state
                == .init(
                    labels: LabelAsSheetPreviewProvider.testLabels().map(\.displayModel),
                    shouldArchive: false,
                    createFolderLabelPresented: false
                )
        )

        await sut.handle(action: .toggleSwitch)

        #expect(
            sut.state
                == .init(
                    labels: LabelAsSheetPreviewProvider.testLabels().map(\.displayModel),
                    shouldArchive: true,
                    createFolderLabelPresented: false
                )
        )
    }

    @Test
    func testState_WhenCreateLabelButtonIsTapped_ItReturnsCorrectState() async {
        let sut = sut(ids: [], type: .conversation)

        await sut.handle(action: .createLabelButtonTapped)

        #expect(sut.state.createFolderLabelPresented)
    }

    @Test
    func testState_WhenLabelActionsSelectionIsChanged_ItReturnsCorrectState() async {
        stubbedLabelAsActions = [IsSelected.partial, .selected, .unselected]
            .enumerated()
            .map { index, status in
                .testData(id: .init(value: UInt64(index)), isSelected: status)
            }
        let firstLabel = stubbedLabelAsActions[0]
        let secondLabel = stubbedLabelAsActions[1]
        let thirdLabel = stubbedLabelAsActions[2]

        let sut = sut(ids: [], type: .conversation)

        await sut.handle(action: .viewAppear)

        #expect(
            sut.state
                == .init(
                    labels: [firstLabel, secondLabel, thirdLabel].map(\.displayModel),
                    shouldArchive: false,
                    createFolderLabelPresented: false
                )
        )

        await sut.handle(action: .selected(firstLabel.displayModel))
        await sut.handle(action: .selected(secondLabel.displayModel))
        await sut.handle(action: .selected(thirdLabel.displayModel))

        #expect(
            sut.state
                == .init(
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

    @Test
    func testLabelAsAction_WhenArchiveNotSelected_ItDoesNotShowUndoToast() async throws {
        try await testLabelAsWithArchiveDisabled(itemType: .message, spyToVerify: { invokedLabelMessage })
    }

    @Test
    func testLabelAsAction_WhenOneLabelIsSelectedAndOtherPartiallySelected_ItLabelsMessage() async throws {
        try await testLabelAsWithArchiveEnabled(
            itemType: .message,
            spyToVerify: { invokedLabelMessage },
            expectToastMessage: L10n.Toast.messageMovedTo(count: 2)
        )
    }

    @Test
    func testLabelAsAction_WhenOneLabelIsSelectedAndOtherPartiallySelected_ItLabelsConversation() async throws {
        try await testLabelAsWithArchiveEnabled(
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
    ) async throws {
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

        await sut.handle(action: .viewAppear)
        await sut.handle(action: .saveButtonTapped)

        #expect(
            spyToVerify() == [
                .init(
                    itemsIDs: itemsIDs,
                    selectedLabelIDs: [selectedLabelID],
                    partiallySelectedLabelIDs: [partiallySelectedLabelID],
                    archive: false
                )
            ]
        )
        #expect(invokedDismissCount == 1)

        #expect(toastStateStore.state.toasts.count == 0)
        #expect(undoSpy.undoCallsCount == 0)
    }

    private func testLabelAsWithArchiveEnabled(
        itemType: MailboxItemType,
        spyToVerify: () -> [LabelAsExecutedWithData],
        expectToastMessage: LocalizedStringResource
    ) async throws {
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

        await sut.handle(action: .viewAppear)
        await sut.handle(action: .toggleSwitch)
        await sut.handle(action: .saveButtonTapped)

        #expect(
            spyToVerify() == [
                .init(
                    itemsIDs: itemsIDs,
                    selectedLabelIDs: [selectedLabelID],
                    partiallySelectedLabelIDs: [partiallySelectedLabelID],
                    archive: true
                )
            ]
        )
        #expect(invokedDismissCount == 1)

        #expect(toastStateStore.state.toasts.count == 1)

        let toastToVerify: Toast = try #require(toastStateStore.state.toasts.last)

        #expect(toastToVerify.message == expectToastMessage.string)

        await toastToVerify.simulateUndoAction()

        #expect(undoSpy.undoCallsCount == 1)
        #expect(toastStateStore.state.toasts == [])
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
