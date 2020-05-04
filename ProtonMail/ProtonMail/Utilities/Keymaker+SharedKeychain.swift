//
//  Keymaker+SharedKeychain.swift
//  ProtonMail - Created on 23/10/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import PMKeymaker

var keymaker = Keymaker(autolocker: Autolocker(lockTimeProvider: userCachedStatus),
                        keychain: KeychainWrapper.keychain)

extension UserCachedStatus: SettingsProvider {}

extension PinProtection {
    init(pin: String) {
        self.init(pin: pin, keychain: KeychainWrapper.keychain)
    }
}

extension NoneProtection {
    init() {
        self.init(keychain: KeychainWrapper.keychain)
    }
}

extension BioProtection {
    init() {
        self.init(keychain: KeychainWrapper.keychain)
    }
}
