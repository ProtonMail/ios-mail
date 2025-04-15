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
import InboxTesting
import proton_app_uniffi
import XCTest

class ConversationActionBarStateStoreTests: BaseTestCase {

    var sut: ConversationActionBarStateStore!
    var handleActionSpy: [BottomBarAction]!
    var stubbedBottomBarActions: AllBottomBarMessageActions!

    override func setUp() {
        super.setUp()

        handleActionSpy = []

        sut = ConversationActionBarStateStore(
            conversationID: .init(value: 1),
            bottomBarConversationActionsProvider: { _, _ in
                    .ok(self.stubbedBottomBarActions)
            }, 
            mailbox: .dummy,
            handleAction: { action in self.handleActionSpy.append(action) }
        )
    }

    func testState_WhenViewLoads_ItReturnsCorrectState() {
        stubbedBottomBarActions = .init(
            hiddenBottomBarActions: [],
            visibleBottomBarActions: [.labelAs, .markUnread]
        )

        XCTAssertEqual(sut.state.count, 0)

        sut.handle(action: .onLoad)

        XCTAssertEqual(sut.state, [.labelAs, .markUnread])
    }

    func testHandleAction_WhenActionIsSelected_ItReturnCorrectAction() {
        sut.handle(action: .actionSelected(.labelAs))
        XCTAssertEqual(handleActionSpy, [.labelAs])
    }

}
