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

import Foundation

final class UILockPinCode {
    typealias Dependencies = AnyObject & HasKeychain

    private let hashHelper = HashHelper()
    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func persist(value: Data, forKey key: KeychainKeys) {
        dependencies.keychain.set(value, forKey: key.rawValue)
    }

    func readPersistedString(forKey key: KeychainKeys) -> Data? {
        dependencies.keychain.data(forKey: key.rawValue)
    }

    func cleanPersistedData() {
        dependencies.keychain.remove(forKey: KeychainKeys.salt.rawValue)
        dependencies.keychain.remove(forKey: KeychainKeys.hashedPinCode.rawValue)
    }

    enum KeychainKeys: String {
        case hashedPinCode = "UILockPinCode.hashedPinCode"
        case salt = "UILockPinCode.salt"
    }
}

extension UILockPinCode: PinCodeProtection {

    func activate(with newPinCode: String) async -> Bool {
        do {
            cleanPersistedData()
            let salt = try hashHelper.generateRandomBytes(count: 8)
            let hashedPinCode = try hashHelper.saltAndHash(value: newPinCode, with: salt)
            persist(value: salt, forKey: .salt)
            persist(value: hashedPinCode, forKey: .hashedPinCode)
        } catch {
            SystemLogger.log(message: error.localizedDescription)
            return false
        }
        return true
    }

    func deactivate() {
        cleanPersistedData()
    }
}

extension UILockPinCode: PinCodeVerifier {

    func isVerified(pinCode: String) async -> Bool {
        guard
            let salt = readPersistedString(forKey: .salt),
            let activePinCode = readPersistedString(forKey: .hashedPinCode)
        else {
            return false
        }
        do {
            let hashedPinCode = try hashHelper.saltAndHash(value: pinCode, with: salt)
            return activePinCode == hashedPinCode
        } catch {
            SystemLogger.log(message: error.localizedDescription)
            return false
        }
    }
}
