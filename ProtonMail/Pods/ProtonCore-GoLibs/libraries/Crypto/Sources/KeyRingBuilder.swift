//
//  KeyRingBuilder.swift
//  ProtonCore-Crypto - Created on 12/12/2022.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import GoLibs
import ProtonCore_Utilities

internal class KeyRingBuilder {
    
    /// internal function to build up go crypto key ring. will auto convert private to public key
    /// - Parameter armoredKeys: armored key list
    /// - Returns: crypto key ring
    func buildPublicKeyRing(armoredKeys: [ArmoredKey]) throws -> CryptoKeyRing {
        let keyRing = try throwingNotNil { error in CryptoNewKeyRing(nil, &error) }
        var keyParsingErrors = [Error]()
        for armoredKey in armoredKeys {
            do {
                let keyToAdd = try throwingNotNil { error in CryptoNewKeyFromArmored(armoredKey.value, &error) }
                if keyToAdd.isPrivate() {
                    let publicKey = try keyToAdd.toPublic()
                    try keyRing.add(publicKey)
                } else {
                    try keyRing.add(keyToAdd)
                }
            } catch let error {
                keyParsingErrors.append(error)
                continue
            }
        }
        guard keyParsingErrors.count != armoredKeys.count else {
            throw CryptoKeyError.noKeyCouldBeParsed(errors: keyParsingErrors)
        }
        return keyRing
    }
    
    func buildPrivateKeyRingUnlock(privateKeys: [DecryptionKey]) throws -> CryptoKeyRing {
        let newKeyRing = try throwing { error in CryptoNewKeyRing(nil, &error) }
        
        guard let keyRing = newKeyRing else {
            throw CryptoError.couldNotCreateKeyRing
        }
        
        var unlockKeyErrors = [Error]()
        
        for key in privateKeys {
            let passSlice = key.passphrase.data
            do {
                let lockedKey = try throwing { error in CryptoNewKeyFromArmored(key.privateKey.value, &error) }
                if let unlockedKey = try lockedKey?.unlock(passSlice) {
                    try keyRing.add(unlockedKey)
                }
            } catch let error {
                unlockKeyErrors.append(error)
                continue
            }
        }
        guard unlockKeyErrors.count != privateKeys.count else {
            throw CryptoKeyError.noKeyCouldBeUnlocked(errors: unlockKeyErrors)
        }
        return keyRing
    }
}
