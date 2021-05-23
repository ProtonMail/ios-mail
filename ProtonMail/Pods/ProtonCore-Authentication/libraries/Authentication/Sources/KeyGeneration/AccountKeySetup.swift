//
//  AccountKeySetup.swift
//  PMAuthentication - Created on 05.01.2021.
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

import Crypto
import OpenPGP
import Foundation
import ProtonCore_DataModel

final class AccountKeySetup {
    
    struct AddressKey {
        
        ///
        let armoredKey: String
        
        ///
        let addressId: String
    }

    struct GeneratedAccountKey {
        
        let addressKeys: [AddressKey]
        let passwordSalt: Data
        let password: String
    }

    func generateAccountKey(addresses: [Address], password: String) throws -> GeneratedAccountKey {
        
        /// generate key salt 128 bits
        let newPasswordSalt: Data = PMNOpenPgp.randomBits(128)
        
        /// generate key hashed password.
        let newHashedPassword = PasswordHash.hashPassword(password, salt: newPasswordSalt)
        
        // new openpgp instance
        let openPGP = PMNOpenPgp.createInstance()!

        let addressKeys = addresses.map { address -> AddressKey in
            
            let key = openPGP.generateKey(address.email, domain: address.email,
                                          passphrase: newHashedPassword,
                                          bits: Int32(2048), time: Int32(0))
            let armoredKey = key.privateKey
            return AddressKey(armoredKey: armoredKey, addressId: address.addressID)
        }
        
        return GeneratedAccountKey(addressKeys: addressKeys, passwordSalt: newPasswordSalt, password: newHashedPassword)
    }

    func setupSetupKeysRoute(password: String, key: GeneratedAccountKey, modulus: String, modulusId: String) throws -> AuthService.SetupKeysEndpoint {
        var error: NSError?

        // for the login password needs to set 80 bits
        // CryptoRandomToken accept the size in bytes for some reason so alwas divide by 8
        let new_salt_for_key: Data = PMNOpenPgp.randomBits(80)

        // generate new verifier
        guard let auth_for_key = try SrpAuthForVerifier(password, modulus, new_salt_for_key) else {
            throw KeySetupError.cantHashPassword
        }

        let verifier_for_key = try auth_for_key.generateVerifier(2048)

        let pwd_auth = PasswordAuth(modulus_id: modulusId, salt: new_salt_for_key.encodeBase64(), verifer: verifier_for_key.encodeBase64())

        /*
         let address: [String: Any] = [
             "AddressID": self.addressID,
             "PrivateKey": self.privateKey,
             "SignedKeyList": self.signedKeyList
         ]
         */

        let addressData = try key.addressKeys.map { addressKey -> [String: Any] in
            guard let cryptoKey = CryptoNewKeyFromArmored(addressKey.armoredKey, &error) else {
                throw KeySetupError.keyReadFailed
            }
            let unlockedKey = try cryptoKey.unlock(key.password.data(using: .utf8))
            guard let keyRing = CryptoKeyRing(unlockedKey) else {
                throw KeySetupError.keyRingGenerationFailed
            }

            let fingerprint = cryptoKey.getFingerprint()
            
            let keylist: [[String: Any]] = [[
                "Fingerprint": fingerprint,
                "Primary": 1,
                "Flags": 3
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
                "PrivateKey": addressKey.armoredKey,
                "SignedKeyList": signedKeyList
            ]

            return address
        }

        return AuthService.SetupKeysEndpoint(addresses: addressData, privateKey: key.addressKeys[0].armoredKey, keySalt: key.passwordSalt.encodeBase64(), passwordAuth: pwd_auth)
    }    
}
