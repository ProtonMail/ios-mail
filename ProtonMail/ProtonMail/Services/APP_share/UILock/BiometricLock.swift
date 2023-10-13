// Copyright (c) 2023 Proton Technologies AG
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
import ProtonCoreKeymaker

final class BiometricLock: UILock {
    enum Constants {
        static let key = "isBiometricLockEnable"
    }

    var isEnabled: Bool {
        keyChain.string(forKey: Constants.key) != nil
    }

    private let keyChain: Keychain
    private let localAuthenticationContext: LAContextProtocol

    init(keyChain: Keychain, localAuthenticationContext: LAContextProtocol = LAContext()) {
        self.keyChain = keyChain
        self.localAuthenticationContext = localAuthenticationContext
    }

    func disable() {
        keyChain.remove(forKey: Constants.key)
    }

    func enable() throws {
        try evaluate()
        keyChain.set(String.randomString(10), forKey: Constants.key)
    }

    func unlock(completion: @escaping (Bool, Error?) -> Void) {
        do {
            try evaluate()
            localAuthenticationContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock the app",
                reply: { result, error in
                    // reply closure is executed on a private queue in the framework which is dangerous to use.
                    // switch to main thread to return instead.
                    DispatchQueue.main.async {
                        completion(result, error)
                    }
                }
            )
        } catch {
            completion(false, error)
        }
    }

    private func evaluate() throws {
        var error: NSError?
        guard localAuthenticationContext.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            throw error ?? .init(domain: "", code: 999, localizedDescription: "Can not evaluate the policy")
        }
    }
}
