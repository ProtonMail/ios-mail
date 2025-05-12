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

@MainActor
class PINStateStoreTests {
    let router: Router<SettingsRoute> = .init()
    var dismissCount = 0

    func makeSut(type: PINScreenType) -> PINStateStore {
        PINStateStore(
            state: .initial(type: type),
            router: router,
            dismiss: { [unowned self] in
                dismissCount += 1
            }
        )
    }

    @Test
    func setPIN_tooShortPinIsTypedAndTrailingButtonIsSelected_ItReturnsValidationError() async {
        let sut = makeSut(type: .set(oldPIN: nil))
        await sut.handle(action: .pinTyped("123"))
        await sut.handle(action: .trailingButtonTapped)

        #expect(sut.state.pinValidation == .failure(L10n.PINLock.Error.tooShort))
        #expect(router.stack == [])
    }

    @Test
    func setPIN_pinIsValid_ItNavigatesToConfirmPINScreen() async {
        let sut = makeSut(type: .set(oldPIN: nil))
        await sut.handle(action: .pinTyped("1234"))
        await sut.handle(action: .trailingButtonTapped)

        #expect(sut.state.pinValidation == .ok)
        #expect(router.stack == [.pin(type: .confirm(oldPIN: nil, newPIN: "1234"))])
    }

    @Test
    func confirmPIN_pinDoesNotMatch_ItReturnsValidationError() async {
        let sut = makeSut(type: .confirm(oldPIN: nil, newPIN: "1234"))
        await sut.handle(action: .pinTyped("1235"))
        await sut.handle(action: .trailingButtonTapped)

        #expect(sut.state.pinValidation == .failure(L10n.Settings.App.repeatedPINValidationError))
        #expect(router.stack == [])
    }

    @Test
    func confirmPIN_pinMatches_ItDismissesScreen() async {
        let sut = makeSut(type: .confirm(oldPIN: nil, newPIN: "1234"))
        await sut.handle(action: .pinTyped("1234"))
        await sut.handle(action: .trailingButtonTapped)

        #expect(sut.state.pinValidation == .ok)
        #expect(router.stack == [])
        #expect(dismissCount == 1)
    }

    @Test
    func verifyPIN_pinIsValidReasonIsDisablePIN_ItDismissesScreen() async {
        let sut = makeSut(type: .verify(reason: .disablePIN))

        await sut.handle(action: .pinTyped("1235"))
        await sut.handle(action: .trailingButtonTapped)

        #expect(sut.state.pinValidation == .ok)
        #expect(router.stack == [])
        #expect(dismissCount == 1)
    }
}
