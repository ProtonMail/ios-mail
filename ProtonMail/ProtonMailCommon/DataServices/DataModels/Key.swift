//
//  Key.swift
//  Proton Mail - Created on 8/1/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import Crypto
import ProtonCore_DataModel

extension Key {
    struct Flags: OptionSet {
        let rawValue: Int

        static let verificationEnabled = Self(rawValue: 1 << 0)
        static let encryptionEnabled = Self(rawValue: 2 << 0)
    }

    var flags: Flags {
        get {
            return Flags(rawValue: self.keyFlags)
        }
        set {
            self.keyFlags = newValue.rawValue
        }
    }

    var publicKey: String {
        return self.privateKey.publicKey
    }

    var fingerprint: String {
        return self.privateKey.fingerprint
    }

    var shortFingerpritn: String {
        let fignerprint = self.fingerprint
        if fignerprint.count > 8 {
            return String(fignerprint.prefix(8))
        }
        return fignerprint
    }
}

extension Array where Element: Key {
    var binPrivKeysArray: [Data] {
        var out: [Data] = []
        var error: NSError?
        for key in self {
            if let privK = ArmorUnarmor(key.privateKey, &error) {
                out.append(privK)
            }
        }
        return out
    }

    var newSchema: Bool {
        for key in self {
            if key.isKeyV2 {
                return true
            }
        }
        return false
    }

}
