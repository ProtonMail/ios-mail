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
import proton_app_uniffi
import Testing

@MainActor
class LockScreenStoreTests {

    lazy var sut: LockScreenStore = .init(
        state: .init(type: .pin, pinAuthenticationError: nil),
        pinVerifier: pinVerifierSpy,
        mailUserSession: { .dummy },
        signOutAllAccountsWrapper: .init(signOutAllAccounts: { [unowned self] _ in
            signOutAllAccountsInvokeCount += 1
            return .ok
        }),
        dismissLock: { [unowned self] in
            dismissLockInvokeCount += 1
        }
    )

    var signOutAllAccountsInvokeCount = 0
    var dismissLockInvokeCount = 0
    private let pinVerifierSpy: PINVerifierSpy = .init()

    @Test
    func handleBiometricAuthenticatedOutput_ItEmitsLockAuthenticatedOutput() async {
        await sut.handle(action: .biometric(.authenticated))

        #expect(dismissLockInvokeCount == 1)
    }

    @Test
    func userEntersValidPin_ItEmitsLockAuthenticatedOutput() async {
        pinVerifierSpy.verifyPinCodeStub = .ok

        await sut.handle(action: .pin(.pin([1, 2, 3, 4, 5])))

        #expect(sut.state.pinAuthenticationError == nil)
        #expect(dismissLockInvokeCount == 1)
    }

    @Test
    func userEntersInvalidPinForFirstTime_ItDisplaysError() async {
        pinVerifierSpy.verifyPinCodeStub = .error(.reason(.incorrectPin))

        await sut.handle(action: .pin(.pin([1, 2, 3, 4, 5])))

        #expect(sut.state.pinAuthenticationError == .custom(L10n.PINLock.invalidPIN.string))
        #expect(dismissLockInvokeCount == 0)
    }

    @Test
    func userEntersInvalidPinForAndThreeAttemntsRemainig_ItDisplaysError() async {
        pinVerifierSpy.remainingPinAttemptsStub = .ok(3)
        pinVerifierSpy.verifyPinCodeStub = .error(.reason(.incorrectPin))

        await sut.handle(action: .pin(.pin([1, 2, 3, 4, 5])))

        #expect(sut.state.pinAuthenticationError == .attemptsRemaining(3))
        #expect(dismissLockInvokeCount == 0)
    }

    @Test
    func pinScreenIsLoadedAndNumberOfAttemptsIsZero_ItVerifiesNumberOfAttemptsAndSendsOutput() async {
        pinVerifierSpy.remainingPinAttemptsStub = .ok(0)

        await sut.handle(action: .pinScreenLoaded)

        #expect(pinVerifierSpy.remainingPinAttemptsCallCount == 1)
        #expect(dismissLockInvokeCount == 1)
    }

    @Test
    func signOutButtonIsTappedOnPINLockScreen_ItSignOutsFromAllAccounts() async {
        await sut.handle(action: .pin(.logOut))

        #expect(signOutAllAccountsInvokeCount == 1)
    }

}
