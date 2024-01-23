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
import ProtonCoreDataModel

extension Key {
    struct Flags: OptionSet, Decodable {
        let rawValue: Int

        /// 2^0 = 1 means the key is not compromised (i.e. if we can trust signatures coming from it)
        static let notCompromised = Self(rawValue: 1 << 0)

        /// 2^1 = 2 means the key is still in use (i.e. not obsolete, we can encrypt messages to it)
        static let notObsolete = Self(rawValue: 2 << 0)
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

    var shortFingerprint: String {
        var capitalized = fingerprint.uppercased()
        if capitalized.count > 8 {
            capitalized = String(capitalized.prefix(8))
        }
        return "0x\(capitalized)"
    }
}
