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
import XCTest

class LabelAsSheetModelTests: BaseTestCase {

    var invokedWithMessagesIDs: [ID] = []
    var invokedWithConversationIDs: [ID] = []
    var stubbedLabelAsActions: [LabelAsAction]!

    func testState_WhenMailboxTypeIsMessageAndLabelsAreLoaded_ItReturnsLabelActions() async {
        stubbedLabelAsActions = LabelAsSheetPreviewProvider.testLabels()
        let messageIDs: [ID] = [.init(value: 7), .init(value: 88)]
        let sut = sut(ids: messageIDs, type: .message)

        await sut.loadLabels()

        XCTAssertEqual(invokedWithMessagesIDs, messageIDs)
        XCTAssertEqual(invokedWithConversationIDs, [])
        XCTAssertEqual(sut.state, .init(
            labels: LabelAsSheetPreviewProvider.testLabels().map(\.displayModel),
            shouldArchive: false
        ))
    }

    func testState_WhenMailboxTypeIsConversationAndArchiveToggleIsTapped_ItReturnsCorrectState() async {
        stubbedLabelAsActions = LabelAsSheetPreviewProvider.testLabels()
        let conversationIDs: [ID] = [.init(value: 1), .init(value: 3)]
        let sut = sut(ids: conversationIDs, type: .conversation)

        await sut.loadLabels()

        XCTAssertEqual(invokedWithMessagesIDs, [])
        XCTAssertEqual(invokedWithConversationIDs, conversationIDs)
        XCTAssertEqual(sut.state, .init(
            labels: LabelAsSheetPreviewProvider.testLabels().map(\.displayModel),
            shouldArchive: false
        ))

        sut.handle(action: .toggleSwitch)

        XCTAssertEqual(sut.state, .init(
            labels: LabelAsSheetPreviewProvider.testLabels().map(\.displayModel),
            shouldArchive: true
        ))
    }

    func testState_WhenLabelActionsSelectionIsChanged_ItReturnsCorrectState() async {
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

        await sut.loadLabels()

        XCTAssertEqual(sut.state, .init(
            labels: [firstLabel, secondLabel, thirdLabel].map(\.displayModel),
            shouldArchive: false
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
            shouldArchive: false
        ))
    }

    // MARK: - Private

    private func sut(ids: [ID], type: MailboxItemType) -> LabelAsSheetModel {
        LabelAsSheetModel(
            input: .init(ids: ids, type: type),
            mailbox: .init(noPointer: .init()),
            actionsProvider: .init(
                message: { _, ids in
                    self.invokedWithMessagesIDs = ids
                    return self.stubbedLabelAsActions
                },
                conversation: { _, ids in
                    self.invokedWithConversationIDs = ids
                    return self.stubbedLabelAsActions
                }
            )
        )
    }

}

private extension LabelAsAction {
    func copy(isSelected: IsSelected) -> Self {
        .init(labelId: labelId, name: name, color: color, isSelected: isSelected)
    }
}
