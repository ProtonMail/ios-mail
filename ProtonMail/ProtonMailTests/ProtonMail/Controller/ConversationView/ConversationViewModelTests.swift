// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail
import ProtonCore_TestingToolkit

class ConversationViewModelTests: XCTestCase {

    private var sut: ConversationViewModel!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let contextProvider = MockCoreDataContextProvider()
        let fakeConversation = Conversation(context: contextProvider.mainContext)
        let apiMock = APIServiceMock()
        let fakeUser = UserManager(api: apiMock, role: .none)
        let reachabilityStub = ReachabilityStub()
        let internetStatusProviderMock = InternetConnectionStatusProvider(notificationCenter: NotificationCenter(), reachability: reachabilityStub)

        sut = ConversationViewModel(labelId: "",
                                    conversation: fakeConversation,
                                    user: fakeUser,
                                    contextProvider: contextProvider,
                                    internetStatusProvider: internetStatusProviderMock,
                                    isDarkModeEnableClosure: {
            return false
        })
    }

    override func tearDownWithError() throws {
        sut = nil

        try super.tearDownWithError()
    }

    func testFocusModeIsEnabledByDefault() {
        XCTAssert(sut.focusedMode)
    }

    func testScrollingDisablesFocusedMode() {
        sut.scrollViewDidScroll()

        XCTAssertFalse(sut.focusedMode)
    }

    func testInstructionToLeaveFocusedModeIsFiredOnce() {
        var callbackCount = 0
        sut.leaveFocusedMode = {
            callbackCount += 1
        }

        sut.scrollViewDidScroll()
        sut.scrollViewDidScroll()

        XCTAssertEqual(callbackCount, 1)
    }
}
