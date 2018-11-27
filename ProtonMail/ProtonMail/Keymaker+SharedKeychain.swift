//
//  Keymaker+SharedKeychain.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 23/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import Keymaker
import UICKeyChainStore

var keymaker = Keymaker(autolocker: Autolocker(lockTimeProvider: userCachedStatus),
                        keychain: sharedKeychain.keychain)

extension UserCachedStatus: SettingsProvider {}

extension PinProtection {
    init(pin: String) {
        self.init(pin: pin, keychain: sharedKeychain.keychain)
    }
}

extension NoneProtection {
    init() {
        self.init(keychain: sharedKeychain.keychain)
    }
}

extension BioProtection {
    init() {
        self.init(keychain: sharedKeychain.keychain)
    }
}
