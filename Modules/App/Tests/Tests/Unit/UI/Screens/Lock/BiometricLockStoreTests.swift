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
import LocalAuthentication
import Testing

class BiometricLockStoreTests {

    var sut: BiometricLockStore!
    var screenOutput: [BiometricLockScreenOutput]!
    private var laContextSpy: LAContextSpy!

    init() {
        screenOutput = []
        laContextSpy = .init()
        sut = .init(
            state: .initial,
            context: { self.laContextSpy },
            output: { output in
                self.screenOutput.append(output)
            }
        )
    }

    deinit {
        sut = nil
        screenOutput = nil
        laContextSpy = nil
    }

    @Test
    func viewLoadsAndCannotEvaluatePolicy_ItDisplaysButtonAndDoesNotEmitOutput() async {
        laContextSpy.canEvaluatePolicyStub = false
        await sut.handle(action: .onLoad)

        #expect(laContextSpy.canEvaluatePolicyCalls == [.deviceOwnerAuthentication])
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

}

private class LAContextSpy: LAContext {
    var canEvaluatePolicyStub = true
    var evaluatePolicyStub = true
    private(set) var canEvaluatePolicyCalls: [LAPolicy] = []
    private(set) var evaluatePolicyCalls: [LAPolicy] = []

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
