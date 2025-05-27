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
import InboxCoreUI
import LocalAuthentication
import Testing

class BiometricLockStoreTests {

    lazy var sut: BiometricLockStore = .init(
        state: .initial,
        method: .builtIn { [unowned self] in self.laContextSpy },
        laContext: { [unowned self] in self.laContextSpy },
        output: { [unowned self] output in
            screenOutput.append(output)
        }
    )
    var screenOutput: [BiometricLockScreenOutput] = []
    private var laContextSpy = LAContextSpy()

    @Test @MainActor
    func viewLoadsAndCannotEvaluatePolicy_ItDisplaysButtonAndDoesNotEmitOutput() async {
        laContextSpy.canEvaluatePolicyStub = false
        await sut.handle(action: .onLoad)

        #expect(laContextSpy.canEvaluatePolicyCalls == [.deviceOwnerAuthentication, .deviceOwnerAuthentication])
        #expect(laContextSpy.evaluatePolicyCalls.count == 0)
        #expect(sut.state.displayUnlockButton == true)
        #expect(screenOutput == [])
    }

    @Test @MainActor
    func viewLoadsAndPolicyEvaluationFails_ItDisplaysButtonAndDoesNotEmitOutput() async {
        laContextSpy.canEvaluatePolicyStub = true
        laContextSpy.evaluatePolicyStub = false

        await sut.handle(action: .onLoad)

        #expect(laContextSpy.canEvaluatePolicyCalls == [.deviceOwnerAuthentication])

        #expect(laContextSpy.evaluatePolicyCalls == [.deviceOwnerAuthentication])

        #expect(sut.state.displayUnlockButton == true)
        #expect(screenOutput == [])
    }

    @Test @MainActor
    func viewLoadsAndPolicyEvaluationSuccess_ItEmitsOutput() async {
        laContextSpy.canEvaluatePolicyStub = true
        laContextSpy.evaluatePolicyStub = true

        await sut.handle(action: .onLoad)

        #expect(screenOutput == [.authenticated])
    }

    @Test @MainActor
    func viewLoadsAndBiometryIsNotConfiguredOnDevice_ItDisplaysAlert() async {
        laContextSpy.canEvaluatePolicyStub = false

        await sut.handle(action: .onLoad)

        #expect(sut.state.alert == cannotEvaluatePolicyAlert)
    }

    @Test @MainActor
    func cannotEvaluatePolicyAlert_OkActionIsTapped_ItDismissesAlert() async {
        laContextSpy.canEvaluatePolicyStub = false

        await sut.handle(action: .onLoad)
        await sut.state.alert?.actions.first(where: { $0.title == "Ok" })?.action()

        #expect(sut.state.alert == nil)
    }

    @Test @MainActor
    func cannotEvaluatePolicyAlert_SignInAgainActionIsTapped_ItDismissesAlertAndEmitsLogOutOutput() async {
        laContextSpy.canEvaluatePolicyStub = false

        await sut.handle(action: .onLoad)
        await sut.state.alert?.actions.first(where: { $0.title == "Sign in again" })?.action()

        #expect(sut.state.alert == nil)
        #expect(screenOutput == [.logOut])
    }

    private var cannotEvaluatePolicyAlert: AlertModel {
        .cannotEvaluatePolicyAlert(
            action: { _ in },
            laContext: { [unowned self] in self.laContextSpy }
        )
    }

}

class LAContextSpy: LAContext {  // FIXME: - Move to separate file
    var canEvaluatePolicyStub = true
    var evaluatePolicyStub = true
    var biometryTypeStub: LABiometryType = .faceID
    private(set) var canEvaluatePolicyCalls: [LAPolicy] = []
    private(set) var evaluatePolicyCalls: [LAPolicy] = []

    // MARK: - LAContext

    override var biometryType: LABiometryType {
        biometryTypeStub
    }

    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        canEvaluatePolicyCalls.append(policy)

        return canEvaluatePolicyStub
    }

    override func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping (Bool, (any Error)?) -> Void
    ) {
        evaluatePolicyCalls.append(policy)
        reply(evaluatePolicyStub, nil)
    }
}
