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

import ProtonCoreKeymaker

// sourcery: mock
protocol PinCodeProtection {
    func activate(with newPinCode: String) async -> Bool
    func deactivate()
}

final class DefaultPinCodeProtection: PinCodeProtection {
    typealias Dependencies = AnyObject &
    HasKeyMakerProtocol &
    HasKeychain &
    HasNotificationCenter

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func activate(with newPinCode: String) async -> Bool {
        await withCheckedContinuation({ continuation in
            LockPreventor.shared.performWhileSuppressingLock {
                _ = dependencies.keyMaker.deactivate(BioProtection(keychain: dependencies.keychain))
            }
            let protection = PinProtection(pin: newPinCode, keychain: dependencies.keychain)
            dependencies.keyMaker.activate(protection) { [unowned self] activated in
                if activated {
                    self.dependencies.notificationCenter.post(name: .appLockProtectionEnabled, object: nil)
                }
                disableAppKey {
                    continuation.resume(returning: activated)
                }
            }
        })
    }

    private func disableAppKey(completion: @escaping (() -> Void)) {
        dependencies.keychain[.keymakerRandomKey] = String.randomString(32)
        if let randomProtection = dependencies.keychain.randomPinProtection {
            dependencies.keyMaker.activate(randomProtection) { [unowned self] activated in
                guard activated else {
                    completion()
                    return
                }
                self.dependencies.notificationCenter.post(name: .appKeyDisabled, object: nil)
                completion()
            }
        } else {
            completion()
        }
    }

    func deactivate() {
        let protection = PinProtection(pin: "doesnotmatter", keychain: dependencies.keychain)
        LockPreventor.shared.performWhileSuppressingLock {
            dependencies.keyMaker.deactivate(protection)
            if let randomProtection = dependencies.keychain.randomPinProtection {
                dependencies.keyMaker.deactivate(randomProtection)
            }
        }
        dependencies.keychain[.keymakerRandomKey] = nil
        dependencies.notificationCenter.post(name: .appLockProtectionDisabled, object: nil, userInfo: nil)
    }
}
