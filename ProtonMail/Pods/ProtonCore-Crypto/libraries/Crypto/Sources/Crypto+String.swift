//
//  Crypto+String.swift
//  ProtonCore-Crypto - Created on 9/11/19.
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
//

import Foundation
import Crypto

extension String {
    
    // TODO:: add test
    public var publicKey: String {
        var error: NSError?
        let key = CryptoNewKeyFromArmored(self, &error)
        if error != nil {
            return ""
        }
        
        return key?.getArmoredPublicKey(nil) ?? ""
    }
    
    //
    public var fingerprint: String {
        var error: NSError?
        let key = CryptoNewKeyFromArmored(self, &error)
        if error != nil {
            return ""
        }
        
        return key?.getFingerprint() ?? ""
    }
    
    //
    var unArmor: Data? {
        return ArmorUnarmor(self, nil)
    }
    
    func getSignature() throws -> String? {
        var error: NSError?
        let clearTextMessage = CryptoNewClearTextMessageFromArmored(self, &error)
        if let err = error {
            throw err
        }
        let dec_out_att: String? = clearTextMessage?.getString()
        return dec_out_att
    }
    
    func split() throws -> SplitMessage? {
        var error: NSError?
        let out = CryptoNewPGPSplitMessageFromArmored(self, &error)
        if let err = error {
            throw err
        }
        return out
    }
    
    // self is private key
    func check(passphrase: String) -> Bool {
        var error: NSError?
        let key = CryptoNewKeyFromArmored(self, &error)
        if error != nil {
            return false
        }
        
        let passSlic = passphrase.data(using: .utf8)
        do {
            let unlockedKey = try key?.unlock(passSlic)
            var result: ObjCBool = true
            try unlockedKey?.isLocked(&result)
            let isUnlock = !result.boolValue
            return isUnlock
        } catch {
            return false
        }
    }
}
