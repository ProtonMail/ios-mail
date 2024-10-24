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

class MailboxActionBarStateStoreTests: BaseTestCase {

    var sut: MailboxActionBarStateStore!
    var invokedAvailableMessageActionsWithIDs: [[ID]]!
    var stubbedAvailableMessageActions: AllBottomBarMessageActions!

    override func setUp() {
        super.setUp()
        invokedAvailableMessageActionsWithIDs = []
        stubbedAvailableMessageActions = .testData

        sut = MailboxActionBarStateStore(
            state: .initial,
            availableActions: .init(message: { _, ids in
                self.invokedAvailableMessageActionsWithIDs.append(ids)

                return self.stubbedAvailableMessageActions
            })
        )
    }

    override func tearDown() {
        sut = nil
        invokedAvailableMessageActionsWithIDs = nil

        super.tearDown()
    }

    func testState_WhenMailboxItemsSelectionIsUpdated_ItReturnsCorrectState() {
        let ids: [ID] = [.init(value: 11)]

        sut.handle(
            action: .mailboxItemsSelectionUpdated(Set(ids), mailbox: .testData, itemType: .message)
        )

        XCTAssertEqual(invokedAvailableMessageActionsWithIDs.count, 1)
        XCTAssertEqual(invokedAvailableMessageActionsWithIDs.first, ids)
        XCTAssertEqual(stubbedAvailableMessageActions, .testData)
    }

    func testState_WhenMailboxItemsSelectionIsUpdatedWithNoSelection_ItReturnsCorrectState() {
        sut.handle(
            action: .mailboxItemsSelectionUpdated([], mailbox: .testData, itemType: .message)
        )

        XCTAssertEqual(invokedAvailableMessageActionsWithIDs.count, 0)
    }

    func testState_WhenMoveToActionIsSelectedAndThenMoveToSheetIsDismissed_ItReturnsCorrectState() {
        XCTAssertNil(sut.state.moveToSheetPresented)

        sut.handle(action: .actionSelected(
            .moveTo, ids: [.init(value: 7)], mailbox: .testData, itemType: .message
        ))

        XCTAssertEqual(sut.state.moveToSheetPresented, .init(ids: [.init(value: 7)], type: .message))

        sut.handle(action: .dismissMoveToSheet)

        XCTAssertNil(sut.state.moveToSheetPresented)
    }

    func testState_WhenLabelAsActionIsSelectedAndThenLabelAsSheetIsDismissed_ItReturnsCorrectState() {
        let ids: Set<ID> = [.init(value: 8)]

        XCTAssertNil(sut.state.labelAsSheetPresented)

        sut.handle(action: .actionSelected(
            .labelAs, ids: ids, mailbox: .testData, itemType: .conversation
        ))

        XCTAssertEqual(sut.state.labelAsSheetPresented, .init(ids: Array(ids), type: .conversation))

        sut.handle(action: .dismissLabelAsSheet)

        XCTAssertNil(sut.state.labelAsSheetPresented)
    }

    func testState_WhenMoreActionIsSelected_ItReturnsCorrectState() {
        let ids: Set<ID> = [.init(value: 9)]

        XCTAssertNil(sut.state.moreActionSheetPresented)

        sut.handle(action: .mailboxItemsSelectionUpdated(ids, mailbox: .testData, itemType: .message))
        sut.handle(action: .actionSelected(.more, ids: ids, mailbox: .testData, itemType: .message))

        XCTAssertEqual(sut.state.moreActionSheetPresented, .init(
            selectedItemsIDs: [.init(value: 9)],
            bottomBarActions: [.markRead, .star, .moveTo, .labelAs],
            moreSheetOnlyActions: [
                .notSpam,
                .permanentDelete,
                .moveToSystemFolder(.init(localId: .init(value: 6), systemLabel: .archive))
            ]
        ))
    }

    func testState_WhenLabelAsActionOnMoreSheetIsSelected_ItReturnsCorrectState() {
        let ids: Set<ID> = [.init(value: 7)]

        sut.handle(action: .moreSheetAction(.labelAs, ids: ids, mailbox: .testData, itemType: .message))

        XCTAssertEqual(sut.state.labelAsSheetPresented, .init(ids: Array(ids), type: .message))
    }

}

private extension Mailbox {
    static var testData: Mailbox {
        .init(noPointer: .init())
    }
}
