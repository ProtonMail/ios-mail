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

struct PINStateStoreTests {

    @MainActor
    class SetPIN {
        lazy var router: Router<SettingsRoute> = .init()
        lazy var sut = PINStateStore(
            state: .initial(type: .set(oldPIN: nil)),
            router: router
        )

        @Test
        func tooShortPinIsTypedAndTrailingButtonIsSelected_ItReturnsValidationError() async {
            await sut.handle(action: .pinTyped("123"))
            await sut.handle(action: .trailingButtonTapped)

            #expect(sut.state.pinValidation == .failure(L10n.PINLock.Error.tooShort))
            #expect(router.stack == [])
        }

        @Test
        func pinIsValid_ItNavigatesToConfirmPINScreen() async {
            await sut.handle(action: .pinTyped("1234"))
            await sut.handle(action: .trailingButtonTapped)

            #expect(sut.state.pinValidation == .ok)
            #expect(router.stack == [.pin(type: .confirm(pin: "1234"))])
        }
    }

    @MainActor
    class ConfirmPIN {
        lazy var router: Router<SettingsRoute> = .init()
        lazy var sut = PINStateStore(
            state: .initial(type: .confirm(pin: "1234")),
            router: router
        )

        @Test
        func typedPINDoesNotMatch_ItReturnsValidationError() async {
            await sut.handle(action: .pinTyped("1235"))
            await sut.handle(action: .trailingButtonTapped)

            #expect(sut.state.pinValidation == .failure(L10n.Settings.App.repeatedPINValidationError))
            #expect(router.stack == [])
        }

        @Test
        func typedPINMatches_ItNavigatesToAppProtectionSelection() async {
            await sut.handle(action: .pinTyped("1234"))
            await sut.handle(action: .trailingButtonTapped)

            #expect(sut.state.pinValidation == .ok)
            #expect(router.stack == [.appProtection])
        }
    }

    @MainActor
    class ChangePIN {
        lazy var router: Router<SettingsRoute> = .init()
        lazy var sut = PINStateStore(
            state: .initial(type: .change(oldPIN: "1234", newPIN: "4321")),
            router: router
        )

        @Test
        func pinIsValid_ItNavigatesToAppProtectionSelection() async {
            await sut.handle(action: .pinTyped("1235"))
            await sut.handle(action: .trailingButtonTapped)

            #expect(sut.state.pinValidation == .ok)
            #expect(router.stack == [.appProtection])
        }
    }

    @MainActor
    class VerifyPIN {
        @Test
        func pinIsValidAndFlowIsDisablePIN_ItNavigatesToAppProtectionSelection() async {
            let router: Router<SettingsRoute> = .init()
            let sut = PINStateStore(
                state: .initial(type: .verify(nextFlow: .disablePIN)),
                router: router
            )

            await sut.handle(action: .pinTyped("1235"))
            await sut.handle(action: .trailingButtonTapped)

            #expect(sut.state.pinValidation == .ok)
            #expect(router.stack == [.appProtection])
        }
    }
}
