//
//  AddressKeySetup.swift
//  PMAuthentication - Created on 21.12.2020.
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
import Foundation
import OpenPGP

final class AddressKeySetup {
    struct GeneratedAddressKey {
        let password: String
        let armoredKey: String
    }

    func generateAddressKey(keyName: String, email: String, password: String, salt: Data) throws -> GeneratedAddressKey {
        guard salt.isEmpty == false else {
            throw KeySetupError.invalidSalt
        }
        
        let hashedPassword = PasswordHash.hashPassword(password, salt: salt)
        
        // new openpgp instance
        let openPGP = PMNOpenPgp.createInstance()!
        let key = openPGP.generateKey(keyName, domain: email,
                                      passphrase: hashedPassword,
                                      bits: Int32(2048), time: Int32(0))
        let armoredKey = key.privateKey
        return GeneratedAddressKey(password: hashedPassword, armoredKey: armoredKey)
    }

    func setupCreateAddressKeyRoute(key: GeneratedAddressKey, modulus: String, modulusId: String,
                                    addressId: String, primary: Bool) throws -> AuthService.CreateAddressKeyEndpoint {
        
        var error: NSError?
        
        let keyData = ArmorUnarmor(key.armoredKey, nil)!
    
        guard let cryptoKey = CryptoNewKey(keyData, &error) else {
            throw KeySetupError.keyReadFailed
        }
        
        let fingerprint = cryptoKey.getFingerprint()

        let unlockedKey = try cryptoKey.unlock(key.password.data(using: .utf8))
        
        guard let keyRing = CryptoKeyRing(unlockedKey) else {
            throw KeySetupError.keyRingGenerationFailed
        }

        let keylist: [[String: Any]] = [[
            "Fingerprint": fingerprint,
            "Primary": 1,
            "Flags": 3
        ]]

        let data = try JSONSerialization.data(withJSONObject: keylist, options: JSONSerialization.WritingOptions())
        let jsonKeylist = String(data: data, encoding: .utf8)!

        let message = CryptoNewPlainMessageFromString(jsonKeylist)
        let signature = try keyRing.signDetached(message)
        
        let signed = signature.getArmored(&error)
        let signedKeyList: [String: Any] = [
            "Data": jsonKeylist,
            "Signature": signed
        ]

        return AuthService.CreateAddressKeyEndpoint(addressID: addressId, privateKey: key.armoredKey, signedKeyList: signedKeyList, primary: primary)
    }    
}
