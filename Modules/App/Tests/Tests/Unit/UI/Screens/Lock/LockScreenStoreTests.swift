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

class LockScreenStoreTests {

    var sut: LockScreenStore!
    var lockScreenOutput: [LockScreenOutput]!
    private var pinVerifierSpy: PINVerifierSpy!

    init() {
        pinVerifierSpy = PINVerifierSpy()
        lockScreenOutput = []
        sut = .init(
            state: .init(type: .pin, pinError: nil),
            pinVerifier: pinVerifierSpy,
            lockOutput: { output in
                self.lockScreenOutput.append(output)
            }
        )
    }

    deinit {
        pinVerifierSpy = nil
        sut = nil
    }

    @Test
    func handleBiometricAuthenticatedOutput_ItEmitsLockAuthenticatedOutput() async {
        await sut.handle(action: .biometric(.authenticated))

        #expect(lockScreenOutput == [.authenticated])
    }

    @Test
    func userEntersValidPin_ItEmitsLockAuthenticatedOutput() async {
        pinVerifierSpy.verifyPinCodeStub = .ok

        await sut.handle(action: .pin(.pin("12345")))

        #expect(sut.state.pinError == nil)
        #expect(lockScreenOutput == [.authenticated])
    }

    @Test
    func userEntersInvalidPinForFirstTime_ItDisplaysError() async {
        pinVerifierSpy.verifyPinCodeStub = .error(.reason(.incorrectPin))

        await sut.handle(action: .pin(.pin("12345")))

        #expect(sut.state.pinError == nil)
        #expect(lockScreenOutput == [])
    }

    @Test
    func userEntersInvalidPinForFirstTime_ItDoesNotDisplayError() async {
        pinVerifierSpy.remainingPinAttemptsStub = .ok(9)
        pinVerifierSpy.verifyPinCodeStub = .error(.reason(.incorrectPin))

        await sut.handle(action: .pin(.pin("12345")))

        #expect(sut.state.pinError == nil)
        #expect(lockScreenOutput == [])
    }

    @Test
    func userEntersInvalidPinForAndThreeAttemntsRemainig_ItDisplaysError() async {
        pinVerifierSpy.remainingPinAttemptsStub = .ok(3)
        pinVerifierSpy.verifyPinCodeStub = .error(.reason(.incorrectPin))

        await sut.handle(action: .pin(.pin("12345")))

        #expect(sut.state.pinError == "3 attempts remaining before sign-out.")
        #expect(lockScreenOutput == [])
    }

    @Test
    func pinScreenIsLoadedAndNumberOfAttemptsIsZero_ItVerifiesNumberOfAttemptsAndSendsOutput() async {
        pinVerifierSpy.remainingPinAttemptsStub = .ok(0)

        await sut.handle(action: .pinScreenLoaded)

        #expect(pinVerifierSpy.remainingPinAttemptsCallCount == 1)
        #expect(lockScreenOutput == [.logOut])
    }

}

private class PINVerifierSpy: PINVerifier, @unchecked Sendable {

    var verifyPinCodeStub: MailSessionVerifyPinCodeResult = .ok
    var remainingPinAttemptsStub: MailSessionRemainingPinAttemptsResult = .ok(10)

    private(set) var remainingPinAttemptsCallCount = 0

    func verifyPinCode(pin: [UInt32]) async -> MailSessionVerifyPinCodeResult {
        verifyPinCodeStub
    }
    
    func remainingPinAttempts() async -> MailSessionRemainingPinAttemptsResult {
        remainingPinAttemptsCallCount += 1

        return remainingPinAttemptsStub
    }

}
