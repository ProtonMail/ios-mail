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
import ProtonTesting
import XCTest

class LabelAsSheetModelTests: BaseTestCase {

    var invokedAvailableActionsWithMessagesIDs: [ID]!
    var invokedAvailableActionsWithConversationIDs: [ID]!
    var invokedDismissCount: Int!
    var stubbedLabelAsActions: [LabelAsAction]!

    override func setUp() {
        super.setUp()

        invokedAvailableActionsWithMessagesIDs = []
        invokedAvailableActionsWithConversationIDs = []
        invokedDismissCount = 0
    }

    override func tearDown() {
        invokedAvailableActionsWithMessagesIDs = nil
        invokedAvailableActionsWithConversationIDs = nil
        invokedDismissCount = nil
        stubbedLabelAsActions = nil

        super.tearDown()
    }

    func testState_WhenMailboxTypeIsMessageAndLabelsAreLoaded_ItReturnsLabelActions() {
        stubbedLabelAsActions = LabelAsSheetPreviewProvider.testLabels()
        let messageIDs: [ID] = [.init(value: 7), .init(value: 88)]
        let sut = sut(ids: messageIDs, type: .message)

        sut.handle(action: .viewAppear)

        XCTAssertEqual(invokedAvailableActionsWithMessagesIDs, messageIDs)
        XCTAssertEqual(invokedAvailableActionsWithConversationIDs, [])
        XCTAssertEqual(sut.state, .init(
            labels: LabelAsSheetPreviewProvider.testLabels().map(\.displayModel),
            shouldArchive: false, 
            createFolderLabelPresented: false
        ))
    }

    func testNavigation_WhenDoneButtonIsTapped_ItReturnsCorrectValue() {
        let sut = sut(ids: [.init(value: 7), .init(value: 88)], type: .message)
        sut.handle(action: .doneButtonTapped)

        XCTAssertEqual(invokedDismissCount, 1)
    }

    func testState_WhenMailboxTypeIsConversationAndArchiveToggleIsTapped_ItReturnsCorrectState() {
        stubbedLabelAsActions = LabelAsSheetPreviewProvider.testLabels()
        let conversationIDs: [ID] = [.init(value: 1), .init(value: 3)]
        let sut = sut(ids: conversationIDs, type: .conversation)

        sut.handle(action: .viewAppear)

        XCTAssertEqual(invokedAvailableActionsWithMessagesIDs, [])
        XCTAssertEqual(invokedAvailableActionsWithConversationIDs, conversationIDs)
        XCTAssertEqual(sut.state, .init(
            labels: LabelAsSheetPreviewProvider.testLabels().map(\.displayModel),
            shouldArchive: false, 
            createFolderLabelPresented: false
        ))

        sut.handle(action: .toggleSwitch)

        XCTAssertEqual(sut.state, .init(
            labels: LabelAsSheetPreviewProvider.testLabels().map(\.displayModel),
            shouldArchive: true, 
            createFolderLabelPresented: false
        ))
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
                .init(
                    labelId: .init(value: UInt64(index)),
                    name: .notUsed,
                    color: .init(value: .notUsed),
                    isSelected: status
                )
            }
        let firstLabel = stubbedLabelAsActions[0]
        let secondLabel = stubbedLabelAsActions[1]
        let thirdLabel = stubbedLabelAsActions[2]

        let sut = sut(ids: [], type: .conversation)

        sut.handle(action: .viewAppear)

        XCTAssertEqual(sut.state, .init(
            labels: [firstLabel, secondLabel, thirdLabel].map(\.displayModel),
            shouldArchive: false,
            createFolderLabelPresented: false
        ))

        sut.handle(action: .selected(firstLabel.displayModel))
        sut.handle(action: .selected(secondLabel.displayModel))
        sut.handle(action: .selected(thirdLabel.displayModel))

        XCTAssertEqual(sut.state, .init(
            labels: [
                firstLabel.copy(isSelected: .unselected).displayModel,
                secondLabel.copy(isSelected: .unselected).displayModel,
                thirdLabel.copy(isSelected: .selected).displayModel,
            ],
            shouldArchive: false, 
            createFolderLabelPresented: false
        ))
    }

    // MARK: - Private

    private func sut(ids: [ID], type: MailboxItemType) -> LabelAsSheetModel {
        LabelAsSheetModel(
            input: .init(ids: ids, type: type),
            mailbox: .init(noPointer: .init()),
            availableLabelAsActions: .init(
                message: { _, ids in
                    self.invokedAvailableActionsWithMessagesIDs = ids
                    return self.stubbedLabelAsActions
                },
                conversation: { _, ids in
                    self.invokedAvailableActionsWithConversationIDs = ids
                    return self.stubbedLabelAsActions
                }
            ), 
            dismiss: { self.invokedDismissCount += 1 }
        )
    }

}

private extension LabelAsAction {
    func copy(isSelected: IsSelected) -> Self {
        .init(labelId: labelId, name: name, color: color, isSelected: isSelected)
    }
}
