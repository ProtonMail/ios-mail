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

final class ConfirmPINStoreTests {
    var state: ConfirmPINState!
    let router = Router<SettingsRoute>()
    lazy var sut: ConfirmPINStore = .init(state: state, router: router)

    @Test
    func validPINIsEntered_AndConfirmButtonIsTapped_ItNavigatesToAppProtectionSelectionScreen() async {
        router.stack = [
            .appProtection,
            .setPIN,
            .confirmPIN(pin: "1234"),
        ]
        state = .initial(pin: "1234")

        await sut.handle(action: .pinTyped("1234"))
        await sut.handle(action: .confirmButtonTapped)

        #expect(router.stack == [.appProtection])
        #expect(sut.state.repeatedPINValidation == .ok)
    }

    @Test
    func noMatchingPINIsEntered_AndConfirmButtonIsTapped_ItDisplaysValidationError() async throws {
        router.stack = [
            .appProtection,
            .setPIN,
            .confirmPIN(pin: "1234"),
        ]
        state = .initial(pin: "12346")

        await sut.handle(action: .pinTyped("1234"))
        #expect(sut.state.repeatedPINValidation == .ok)

        await sut.handle(action: .confirmButtonTapped)
        let validationMessage = try #require(sut.state.repeatedPINValidation.failure)
        #expect(validationMessage == "The PIN codes must match!")
    }
}


// FIXME: - Move somewhere
extension FormTextInput.ValidationStatus {

    var failure: LocalizedStringResource? {
        if case let .failure(text) = self {
            return text
        }
        return nil
    }

}
