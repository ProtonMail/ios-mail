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
    static let keymakerRandomKey = StringKeychainKey(name: "randomPinForProtection")
}

final class StringKeychainKey: KeychainKeys {
    let name: String

    init(name: String) {
        self.name = name
    }
}

extension Keychain {
    subscript(_ key: StringKeychainKey) -> String? {
        get {
            string(forKey: key.name)
        }
        set {
            if let newValue {
                set(newValue, forKey: key.name)
            } else {
                remove(forKey: key.name)
            }
        }
    }
}
