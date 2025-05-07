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

@testable import ProtonMail
import InboxCore
import Testing

final class SetPINStoreTests {

    var state: SetPINState!
    let router = Router<SettingsRoute>()
    lazy var sut: SetPINStore = .init(state: state, router: router)

    @Test
    func validPINIsEntered_NextIsTapped_ItNavigatesToPINConfirmationScreen() async {
        router.stack = [
            .setPIN
        ]
        state = .initial

        await sut.handle(action: .pinTyped("1234"))
        await sut.handle(action: .nextTapped)
        #expect(router.stack == [.setPIN, .confirmPIN(pin: "1234")])
    }

    @Test
    func invalidPINIsEntered_NextIsTapped_ItShowsValidationError() async throws {
        router.stack = [
            .setPIN
        ]
        state = .initial

        await sut.handle(action: .pinTyped("123"))
        await sut.handle(action: .nextTapped)
        #expect(router.stack == [.setPIN])

        let validationMessage = try #require(sut.state.pinValidation.failure)
        #expect(validationMessage == "PIN is too short")
    }

}
