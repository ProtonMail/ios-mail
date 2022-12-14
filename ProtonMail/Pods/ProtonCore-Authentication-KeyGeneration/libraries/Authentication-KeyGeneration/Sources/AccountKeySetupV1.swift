//
//  AccountKeySetupV1.swift
//  ProtonCore-Authentication-KeyGeneration - Created on 05.01.2021.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import GoLibs
import ProtonCore_Crypto
import OpenPGP
import Foundation
import ProtonCore_Authentication
import ProtonCore_DataModel
import ProtonCore_Utilities

@available(*, deprecated, renamed: "AccountKeySetupV2", message: "keep this until AccountKeySetupV2 is fully tested")
final class AccountKeySetupV1 {
    
    struct AddressKeyV1 {
        
        ///
        let armoredKey: ArmoredKey
        
        ///
        let addressId: String
    }

    struct GeneratedAccountKeyV1 {
        
        let addressKeys: [AddressKeyV1]
        let passwordSalt: Data
        let password: Passphrase
    }

    func generateAccountKey(addresses: [Address], password: String) throws -> GeneratedAccountKeyV1 {
        
        /// generate key salt 128 bits
        let newPasswordSalt: Data = PMNOpenPgp.randomBits(PasswordSaltSize.accountKey.int32Bits)
        
        /// generate key hashed password.
        let newPassphrase = PasswordHash.passphrase(password, salt: newPasswordSalt)
        
        let addressKeys = try addresses.filter { $0.type != .externalAddress }.map { address -> AddressKeyV1 in
            let armoredKey = try Generator.generateECCKey(email: address.email, passphase: newPassphrase)
            return AddressKeyV1(armoredKey: armoredKey, addressId: address.addressID)
        }
        if addressKeys.isEmpty {
            throw KeySetupError.keyGenerationFailed
        }
        return GeneratedAccountKeyV1(addressKeys: addressKeys, passwordSalt: newPasswordSalt, password: newPassphrase)
    }

    func setupSetupKeysRoute(password: String, key: GeneratedAccountKeyV1, modulus: String, modulusId: String) throws -> AuthService.SetupKeysEndpoint {
        var error: NSError?

        // for the login password needs to set 80 bits
        // accept the size in bytes for some reason so alwas divide by 8
        let newSaltForKey: Data = PMNOpenPgp.randomBits(PasswordSaltSize.login.int32Bits)

        // generate new verifier
        guard let authForKey = try SrpAuthForVerifier(password, modulus, newSaltForKey) else {
            throw KeySetupError.cantHashPassword
        }

        let verifierForKey = try authForKey.generateVerifier(2048)

        let passwordAuth = PasswordAuth(modulusID: modulusId, salt: newSaltForKey.encodeBase64(), verifer: verifierForKey.encodeBase64())

        /*
         let address: [String: Any] = [
             "AddressID": self.addressID,
             "PrivateKey": self.privateKey,
             "SignedKeyList": self.signedKeyList
         ]
         */

        let addressData = try key.addressKeys.map { addressKey -> [String: Any] in
            // lagcy logic and will be deprecated. we will not migrate it
            guard let cryptoKey = CryptoNewKeyFromArmored(addressKey.armoredKey.value, &error) else {
                throw KeySetupError.keyReadFailed
            }
            let unlockedKey = try cryptoKey.unlock(key.password.data)
            guard let keyRing = CryptoKeyRing(unlockedKey) else {
                throw KeySetupError.keyRingGenerationFailed
            }

            let fingerprint = cryptoKey.getFingerprint()
            
            let keylist: [[String: Any]] = [[
                "Fingerprint": fingerprint,
                "Primary": 1,
                "Flags": KeyFlags.signupKeyFlags.rawValue
            ]]

            let jsonKeylist = keylist.json()
            let message = CryptoNewPlainMessageFromString(jsonKeylist)
            let signature = try keyRing.signDetached(message)
            let signed = signature.getArmored(&error)
            let signedKeyList: [String: Any] = [
                "Data": jsonKeylist,
                "Signature": signed
            ]

            let address: [String: Any] = [
                "AddressID": addressKey.addressId,
                "PrivateKey": addressKey.armoredKey.value,
                "SignedKeyList": signedKeyList
            ]

            return address
        }

        guard let firstaddressKey = key.addressKeys.first else {
            throw KeySetupError.keyGenerationFailed
        }
        
        return AuthService.SetupKeysEndpoint(addresses: addressData,
                                             privateKey: firstaddressKey.armoredKey,
                                             keySalt: key.passwordSalt.encodeBase64(),
                                             passwordAuth: passwordAuth)
    }    
}
