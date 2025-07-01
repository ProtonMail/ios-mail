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

import LocalAuthentication

public class LAContextSpy: LAContext {
    public var canEvaluatePolicyStub = true
    public var evaluatePolicyStub = true
    public var biometryTypeStub: LABiometryType = .faceID
    private(set) public var canEvaluatePolicyCalls: [LAPolicy] = []
    private(set) public var evaluatePolicyCalls: [LAPolicy] = []

    // MARK: - LAContext

    public override var biometryType: LABiometryType {
        biometryTypeStub
    }

    public override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        canEvaluatePolicyCalls.append(policy)

        return canEvaluatePolicyStub
    }

    public override func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping (Bool, (any Error)?) -> Void
    ) {
        evaluatePolicyCalls.append(policy)
        reply(evaluatePolicyStub, nil)
    }
}
