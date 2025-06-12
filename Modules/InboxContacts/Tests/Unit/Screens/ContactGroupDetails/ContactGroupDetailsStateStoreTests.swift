// Copyright (c) 2025 Proton Technologies AG
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

@testable import InboxContacts
import InboxTesting
import proton_app_uniffi
import XCTest

final class ContactGroupDetailsStateStoreTests: BaseTestCase {
    private var sut: ContactGroupDetailsStateStore!
    private var initialState: ContactGroupItem!
    private var draftPresenterSpy: ContactsDraftPresenterSpy!

    override func setUp() {
        super.setUp()
        initialState = .advisorsGroup
        draftPresenterSpy = .init()

        sut = ContactGroupDetailsStateStore(state: initialState, draftPresenter: draftPresenterSpy)
    }

    override func tearDown() {
        sut = nil
        initialState = nil
        draftPresenterSpy = nil
        super.tearDown()
    }

    func testInitialState_isSetCorrectly() {
        XCTAssertEqual(sut.state, initialState)
    }

    func testSendGroupMessageTappedAction_ItPresentsDraftWithContactGroup() async {
        await sut.handle(action: .sendGroupMessageTapped)

        XCTAssertEqual(draftPresenterSpy.openDraftGroupCalls.count, 1)
        XCTAssertEqual(draftPresenterSpy.openDraftGroupCalls, [initialState])
    }
}
