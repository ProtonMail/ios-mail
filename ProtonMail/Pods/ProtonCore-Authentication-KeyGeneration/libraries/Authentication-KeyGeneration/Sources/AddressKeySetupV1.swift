//
//  AddressKeySetup.swift
//  ProtonCore-Authentication-KeyGeneration - Created on 21.12.2020.
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

#if canImport(Crypto_VPN)
import Crypto_VPN
#elseif canImport(Crypto)
import Crypto
#endif
#if canImport(ProtonCore_Crypto_VPN)
import ProtonCore_Crypto_VPN
#elseif canImport(ProtonCore_Crypto)
import ProtonCore_Crypto
#endif
import Foundation
import ProtonCore_Authentication
import ProtonCore_DataModel

@available(*, deprecated, renamed: "AddressKeySetupV2", message: "keep this until AddressKeySetupV2 is fully tested")
final class AddressKeySetupV1 {
    
    struct GeneratedAddressKeyV1 {
        let password: String
        let armoredKey: String
    }

    func generateAddressKey(keyName: String, email: String, password: String, salt: Data) throws -> GeneratedAddressKeyV1 {
        guard !salt.isEmpty else {
            throw KeySetupError.invalidSalt
        }
        
        let hashedPassword = PasswordHash.hashPassword(password, salt: salt)
        
        // new openpgp instance
        var error: NSError?
        let armoredKey = HelperGenerateKey(keyName, email, hashedPassword.data(using: .utf8),
                                           PublicKeyAlgorithms.x25519.raw, 0, &error)
        if let err = error {
            throw err
        }
        return GeneratedAddressKeyV1(password: hashedPassword, armoredKey: armoredKey)
    }

    func setupCreateAddressKeyRoute(key: GeneratedAddressKeyV1, modulus: String, modulusId: String,
                                    addressId: String, isPrimary: Bool) throws -> AuthService.CreateAddressKeyEndpointV1 {
        
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
            "Flags": KeyFlags.signupKeyFlags.rawValue
        ]]

        let data = try JSONSerialization.data(withJSONObject: keylist)
        let jsonKeylist = String(data: data, encoding: .utf8)!

        let message = CryptoNewPlainMessageFromString(jsonKeylist)
        let signature = try keyRing.signDetached(message)
        
        let signed = signature.getArmored(&error)
        let signedKeyList: [String: Any] = [
            "Data": jsonKeylist,
            "Signature": signed
        ]

        return AuthService.CreateAddressKeyEndpointV1(addressID: addressId, privateKey: key.armoredKey,
                                                      signedKeyList: signedKeyList, isPrimary: isPrimary)
    }    
}
