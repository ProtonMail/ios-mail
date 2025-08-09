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

@testable import InboxCoreUI
import InboxTesting
import Testing

@MainActor
struct ToastStateStoreTests {
    private var sut: ToastStateStore = .init(initialState: .initial)

    @Test
    func testState_WhenPresentingThreeToastsAndOneTwice_HasTwoToastsInCorrectOrder() throws {
        let firstToast = Toast.error(message: "Test #1")
        let secondToast = Toast.error(message: "Test #2")

        sut.present(toast: firstToast)
        sut.present(toast: secondToast)
        sut.present(toast: firstToast)

        #expect(sut.state.toasts.count == 2)
        #expect(sut.state.toasts == [firstToast, secondToast])
    }

    @Test
    func testState_WhenDismissingSameToastTwice_HasOnlyOneToast() throws {
        let firstToast = Toast.error(message: "Test #1")
        let secondToast = Toast.error(message: "Test #2")

        sut.present(toast: firstToast)
        sut.present(toast: secondToast)
        sut.present(toast: firstToast)

        sut.dismiss(toast: firstToast)
        sut.dismiss(toast: firstToast)

        #expect(sut.state.toasts.count == 1)
        #expect(sut.state.toasts == [secondToast])
    }

    @Test
    func testState_WhenDismissingByID_DismissesCorrectToast() throws {
        let firstToast = Toast.error(message: "Test #42")
        let secondToast = Toast.error(message: "Test #99")

        sut.present(toast: firstToast)
        sut.present(toast: secondToast)

        sut.dismiss(withID: secondToast.id)

        #expect(sut.state.toasts.count == 1)
        #expect(sut.state.toasts == [firstToast])
    }
}
