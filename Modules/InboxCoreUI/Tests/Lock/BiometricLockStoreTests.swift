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

import InboxCore
import InboxTesting
import LocalAuthentication
import Testing

@testable import InboxCoreUI

@MainActor
final class BiometricLockStoreTests {
    lazy var sut: BiometricLockStore = .init(
        state: .initial,
        method: .builtIn { [unowned self] in laContextSpy },
        laContext: { [unowned self] in self.laContextSpy },
        output: { [unowned self] output in
            screenOutput.append(output)
        }
    )
    var screenOutput: [BiometricLockScreenOutput] = []
    private var laContextSpy = LAContextSpy()

    @Test
    func viewLoadsAndCannotEvaluatePolicy_ItDisplaysButtonAndDoesNotEmitOutput() async {
        laContextSpy.canEvaluatePolicyStub = false
        await sut.handle(action: .onLoad)

        #expect(laContextSpy.canEvaluatePolicyCalls == [.deviceOwnerAuthentication, .deviceOwnerAuthentication])
        #expect(laContextSpy.evaluatePolicyCalls.count == 0)
        #expect(sut.state.displayUnlockButton == true)
        #expect(screenOutput == [])
    }

    @Test
    func viewLoadsAndPolicyEvaluationFails_ItDisplaysButtonAndDoesNotEmitOutput() async {
        laContextSpy.canEvaluatePolicyStub = true
        laContextSpy.evaluatePolicyStub = false

        await sut.handle(action: .onLoad)

        #expect(laContextSpy.canEvaluatePolicyCalls == [.deviceOwnerAuthentication])

        #expect(laContextSpy.evaluatePolicyCalls == [.deviceOwnerAuthentication])

        #expect(sut.state.displayUnlockButton == true)
        #expect(screenOutput == [])
    }

    @Test
    func viewLoadsAndPolicyEvaluationSuccess_ItEmitsOutput() async {
        laContextSpy.canEvaluatePolicyStub = true
        laContextSpy.evaluatePolicyStub = true

        await sut.handle(action: .onLoad)

        #expect(screenOutput == [.authenticated])
    }

    @Test
    func viewLoadsAndBiometryIsNotConfiguredOnDevice_ItDisplaysAlert() async {
        laContextSpy.canEvaluatePolicyStub = false

        await sut.handle(action: .onLoad)

        #expect(sut.state.alert == policyUnavailableAlert)
    }

    @Test
    func policyUnavailableAlert_OkActionIsTapped_ItDismissesAlert() async {
        laContextSpy.canEvaluatePolicyStub = false

        await sut.handle(action: .onLoad)
        await sut.state.alert?.actions.first(where: { $0.title == CommonL10n.ok })?.action()

        #expect(sut.state.alert == nil)
    }

    @Test
    func policyUnavailableAlert_SignInAgainActionIsTapped_ItDismissesAlertAndEmitsLogOutOutput() async {
        laContextSpy.canEvaluatePolicyStub = false

        await sut.handle(action: .onLoad)
        await sut.state.alert?.actions
            .first(where: { $0.title == L10n.BiometricLock.BiometricsNotAvailableAlert.signInAgainAction })?
            .action()

        #expect(sut.state.alert == nil)
        #expect(screenOutput == [.logOut])
    }

    private var policyUnavailableAlert: AlertModel {
        .policyUnavailableAlert(
            action: { _ in },
            laContext: { [unowned self] in self.laContextSpy }
        )
    }
}
