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

class MoveToSheetModelTests: BaseTestCase {

    var invokedAvailableActionsWithMessagesIDs: [ID]!
    var invokedAvailableActionsWithConversationIDs: [ID]!
    var invokedNavigation: [MoveToSheetNavigation]!
    var stubbedMoveToActions: [MoveAction]!

    override func setUp() {
        super.setUp()
        invokedAvailableActionsWithMessagesIDs = []
        invokedAvailableActionsWithConversationIDs = []
        invokedNavigation = []
        stubbedMoveToActions = [
            .systemFolder(.init(localId: .init(value: 1), name: .inbox, isSelected: .unselected)),
            .customFolder(.init(
                localId: .init(value: 2),
                name: "Private",
                color: nil,
                children: [],
                isSelected: .selected
            ))
        ]
    }

    override func tearDown() {
        invokedAvailableActionsWithMessagesIDs = nil
        invokedAvailableActionsWithConversationIDs = nil
        invokedNavigation = nil
        stubbedMoveToActions = nil

        super.tearDown()
    }

    func testState_WhenMailboxTypeIsMessageAndViewAppear_ItReturnsMoveToActions() {
        let ids: [ID] = [.init(value: 777), .init(value: 111)]
        let sut = sut(input: .init(ids: ids, type: .message))

        sut.handle(action: .viewAppear)

        XCTAssertEqual(invokedAvailableActionsWithMessagesIDs, ids)
        XCTAssertEqual(invokedAvailableActionsWithConversationIDs, [])
    }

    func testState_WhenMailboxTypeIsConversationAndViewAppear_ItReturnsMoveToActions() {
        let ids: [ID] = [.init(value: 777), .init(value: 111)]
        let sut = sut(input: .init(ids: ids, type: .conversation))

        sut.handle(action: .viewAppear)

        XCTAssertEqual(invokedAvailableActionsWithMessagesIDs, [])
        XCTAssertEqual(invokedAvailableActionsWithConversationIDs, ids)
    }

    func testNavigation_WhenCreateFolderActionIsHandled_ItReturnsCorrectNavigation() {
        let sut = sut(input: .init(ids: [], type: .message))

        sut.handle(action: .createFolderTapped)

        XCTAssertEqual(invokedNavigation, [.createFolder])
    }

    func testNavigation_WhenMoveToActionIsHandled_ItReturnsCorrectNavigation() {
        let sut = sut(input: .init(ids: [], type: .message))

        sut.handle(action: .folderTapped(id: .random()))

        XCTAssertEqual(invokedNavigation, [.dismiss])
    }

    // MARK: - Private

    private func sut(input: LabelAsActionSheetInput) -> MoveToSheetModel {
        .init(
            input: input,
            mailbox: .init(noPointer: .init()),
            availableMoveToActions: .init(
                message: { _, ids in
                    self.invokedAvailableActionsWithMessagesIDs = ids
                    return []
                },
                conversation: { _, ids in
                    self.invokedAvailableActionsWithConversationIDs = ids
                    return []
                }
            ),
            navigation: { navigation in self.invokedNavigation.append(navigation) }
        )
    }

}
