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

@testable import InboxCoreUI
import InboxTesting
import XCTest

final class ToastStateStoreTests: BaseTestCase {

    private var sut: ToastStateStore!

    override func setUp() {
        super.setUp()
        sut = .init(initialState: .initial)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testState_WhenPresentingThreeToastsAndOneTwice_HasTwoToastsInCorrectOrder() throws {
        let firstToast = Toast.error(message: "Test #1")
        let secondToast = Toast.error(message: "Test #2")

        sut.present(toast: firstToast)
        sut.present(toast: secondToast)
        sut.present(toast: firstToast)

        XCTAssertEqual(sut.state.toasts.count, 2)
        XCTAssertEqual(sut.state.toasts, [firstToast, secondToast])
    }

    func testState_WhenDismissingSameToastTwice_HasOnlyOneToast() throws {
        let firstToast = Toast.error(message: "Test #1")
        let secondToast = Toast.error(message: "Test #2")

        sut.present(toast: firstToast)
        sut.present(toast: secondToast)
        sut.present(toast: firstToast)

        sut.dismiss(toast: firstToast)
        sut.dismiss(toast: firstToast)

        XCTAssertEqual(sut.state.toasts.count, 1)
        XCTAssertEqual(sut.state.toasts, [secondToast])
    }

}
