//
//  AccountKeySetup.swift
//  PMAuthentication
//
//  Created by Igor Kulman on 05.01.2021.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import Crypto
import Foundation

final class AccountKeySetup {
    struct AddressKey {
        let cryptoKey: CryptoKey
        let armoredKey: String
        let addressId: String
    }

    struct GeneratedAccountKey {
        let addressKeys: [AddressKey]
        let passwordSalt: Data
        let password: String
    }

    func generateAccountKey(addresses: [Address], password: String) throws -> GeneratedAccountKey {
        var error: NSError?

        // generate key salt 128 bits
        // CryptoRandomToken accept the size in bytes for some reason so alwas divide by 8
        guard let newPasswordSalt: Data = CryptoRandomToken(16, &error) else {
            throw error ?? KeySetupError.randomTokenGenerationFailed
        }

        //generate key hashed password.
        let newHashedPassword = PasswordHash.hashPassword(password, salt: newPasswordSalt)

        let addressKeys = try addresses.map { address -> AddressKey in
            guard let passwordLessKey = CryptoGenerateKey(address.email, address.email, "rsa", 2048, &error) else {
                throw error ?? KeySetupError.keyGenerationFailed
            }
            let key = try passwordLessKey.lock(newHashedPassword.data(using: .utf8))
            let armoredKey = key.armor(&error)
            return AddressKey(cryptoKey: key, armoredKey: armoredKey, addressId: address.ID)
        }
        return GeneratedAccountKey(addressKeys: addressKeys, passwordSalt: newPasswordSalt, password: newHashedPassword)
    }

    func setupSetupKeysRoute(password: String, key: GeneratedAccountKey, modulus: String, modulusId: String) throws -> AuthService.SetupKeysEndpoint {
        var error: NSError?

        // for the login password needs to set 80 bits
        // CryptoRandomToken accept the size in bytes for some reason so alwas divide by 8
        guard let new_salt_for_key: Data = CryptoRandomToken(10, &error) else {
            throw error ?? KeySetupError.randomTokenGenerationFailed
        }

        //generate new verifier
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
            let unlockedKey = try addressKey.cryptoKey.unlock(key.password.data(using: .utf8))
            guard let keyRing = CryptoKeyRing(unlockedKey) else {
                throw KeySetupError.keyRingGenerationFailed
            }

            let fingerprint = addressKey.cryptoKey.getFingerprint()

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
