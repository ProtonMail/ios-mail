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

class KeychainKeys {
    static let autolockTimeout = RawRepresentableKeychainKey<AutolockTimeout>(
        name: "autoLockTime",
        defaultValue: .always
    )

    static let keymakerRandomKey = StringKeychainKey(name: "randomPinForProtection")

    static let metadataStripping = RawRepresentableKeychainKey<AttachmentMetadataStripping>(
        name: "metadataStripping",
        defaultValue: .sendAsIs
    )
}

final class StringKeychainKey: KeychainKeys {
    let name: String

    init(name: String) {
        self.name = name
    }
}

final class RawRepresentableKeychainKey<T: RawRepresentable>: KeychainKeys where T.RawValue: LosslessStringConvertible {
    let rawValueKey: StringKeychainKey
    let defaultValue: T

    init(name: String, defaultValue: T) {
        rawValueKey = StringKeychainKey(name: name)
        self.defaultValue = defaultValue
    }
}

extension Keychain {
    subscript(_ key: StringKeychainKey) -> String? {
        get {
            do {
                return try stringOrError(forKey: key.name)
            } catch {
                SystemLogger.log(error: error)
                return nil
            }
        }
        set {
            do {
                if let newValue {
                    try setOrError(newValue, forKey: key.name)
                } else {
                    try removeOrError(forKey: key.name)
                }
            } catch {
                SystemLogger.log(error: error)
            }
        }
    }

    subscript<T>(_ key: RawRepresentableKeychainKey<T>) -> T {
        get {
            guard let stringValue = self[key.rawValueKey] else {
                return key.defaultValue
            }

            guard let rawValue = T.RawValue(stringValue), let parsedValue = T(rawValue: rawValue) else {
                self[key.rawValueKey] = nil
                return key.defaultValue
            }

            return parsedValue
        }
        set {
            self[key.rawValueKey] = newValue.rawValue.description
        }
    }
}
