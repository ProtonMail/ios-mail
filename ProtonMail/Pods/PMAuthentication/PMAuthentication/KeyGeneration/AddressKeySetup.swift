//
//  AddressKeySetup.swift
//  PMAuthentication
//
//  Created by Igor Kulman on 21.12.2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Crypto
import Foundation

final class AddressKeySetup {
    struct GeneratedAddressKey {
        let cryptoKey: CryptoKey
        let password: String
        let armoredKey: String
    }

    func generateAddressKey(keyName: String, email: String, password: String, salt: Data) throws -> GeneratedAddressKey {
        var error: NSError?

        let hashedPassword = PasswordHash.hashPassword(password, salt: salt)

        guard let passwordLessKey = CryptoGenerateKey(keyName, email, "rsa", 2048, &error) else {
            throw KeySetupError.keyGenerationFailed
        }
        let key = try passwordLessKey.lock(hashedPassword.data(using: .utf8))
        let armoredKey = key.armor(&error)
        return GeneratedAddressKey(cryptoKey: key, password: hashedPassword, armoredKey: armoredKey)
    }

    func setupCreateAddressKeyRoute(key: GeneratedAddressKey, modulus: String, modulusId: String, addressId: String, primary: Bool) throws -> AuthService.CreateAddressKeyEndpoint {
        let unlockedKey = try key.cryptoKey.unlock(key.password.data(using: .utf8))
        guard let keyRing = CryptoKeyRing(unlockedKey) else {
            throw KeySetupError.keyRingGenerationFailed
        }

        let fingerprint = key.cryptoKey.getFingerprint()

        let keylist: [[String: Any]] = [[
            "Fingerprint": fingerprint,
            "Primary": 1,
            "Flags": 3
        ]]

        let data = try JSONSerialization.data(withJSONObject: keylist, options: JSONSerialization.WritingOptions())
        let jsonKeylist = String(data: data, encoding: .utf8)!

        let message = CryptoNewPlainMessageFromString(jsonKeylist)
        let signature = try keyRing.signDetached(message)

        var error: NSError?
        let signed = signature.getArmored(&error)
        let signedKeyList: [String: Any] = [
            "Data": jsonKeylist,
            "Signature": signed
        ]

        return AuthService.CreateAddressKeyEndpoint(addressID: addressId, privateKey: key.armoredKey, signedKeyList: signedKeyList, primary: primary)
    }    
}
