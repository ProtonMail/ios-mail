//
//  AccountKeySetup.swift
//  ProtonCore-Authentication-KeyGeneration - Created on 06/01/2020
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
import OpenPGP
import Foundation
import ProtonCore_Authentication
import ProtonCore_DataModel
import ProtonCore_Utilities

/// class for key migeration phase 2
final class AccountKeySetup {
    
    /// account level key. on phase 2 user key used for
    struct UserKey {
        /// armored key
        let armoredKey: ArmoredKey
        
        /// user key password salt - shoudle be 128 bits
        let passwordSalt: Data
        
        /// hashed password with password salt. this is the key passphrase
        let password: Passphrase
    }
    
    /// address key
    struct AddressKey {
        
        /// address id
        let addressId: String
        
        /// armored key
        let armoredKey: ArmoredKey
        
        /// on phase 2. token used to encrypt address key
        let token: ArmoredMessage
        
        /// detached signaute.
        let signature: ArmoredSignature
        
        /// signed key metadata
        ///     simple:
        ///     let keylist: [[String: Any]] = [[
        ///         "Fingerprint": "key.fingerprint",  //address key fingerprint
        ///         "SHA256Fingerprints": "key.sha256fingerprint" // address key sha256Fingerprint,
        ///         "Primary": 1,    // 1 or 0   is it a primary key
        ///         "Flags": 3    //ref keyFlags in dataModel
        ///     ]]
        ///
        ///     let signedKeyList: [String: Any] = [
        ///         "Data": JSON(keylist),      // encode key list to json
        ///         "Signature": SIGNED((JSON(keylist))    // user address key sign detached.
        ///     ]
        let signedKeyList: [String: Any]
    }

    /// new account key struct
    struct GeneratedAccountKey {
        
        /// account level user key
        let userKey: UserKey
        
        /// user address keys
        let addressKeys: [AddressKey]
    }
    
    /// generate account user-key address key. used right after create a new user and address.
    ///   at this moment address doesn't have any key yet
    /// - Parameters:
    ///   - addresses: address object get from api
    ///   - password: user login password
    /// - Returns: `GeneratedAccountKey`
    func generateAccountKey(addresses: [Address], password: String) throws -> GeneratedAccountKey {
        /// generate key salt 128 bits
        let newPasswordSalt: Data = PMNOpenPgp.randomBits(PasswordSaltSize.accountKey.int32Bits)
        /// generate key hashed password.
        let userKeyPassphrase = PasswordHash.passphrase(password, salt: newPasswordSalt)
        
        guard let firstAddr = addresses.first(where: { $0.type != .externalAddress }) else {
            throw KeySetupError.keyGenerationFailed
        }
        
        // in our system the PGP `User ID Packet-Tag 13` we use email address as username and email address
        let armoredUserKey = try Generator.generateECCKey(email: firstAddr.email, passphase: userKeyPassphrase)
        
        /// blow logic could be in function `setupSetupKeysRoute`.
        ///   - but for the securty reason. we generate the password and token here.
        ///   - we dont want it keep in the memory and pass cross different functions.
        ///   - so we genrete here and encrypt it here try to keep it in this function scope.        ///

        let addressKeys = try addresses.filter { $0.type != .externalAddress }.map { addr -> AddressKey in
            // generate addr passphrase
            let addrPassphrase = PasswordHash.genAddrPassphrase()
            
            /// generate a new key.  id: address email.  passphrase: hexed secret (should be 64 bytes) with default key type
            let armoredAddrKey = try Generator.generateECCKey(email: addr.email, passphase: addrPassphrase)
            
            /// generate token.   token is hexed secret encrypted by `UserKey.publicKey`. Note: we don't need to inline sign
            let token = try addrPassphrase.encrypt(publicKey: armoredUserKey)
            
            /// gnerenate a detached signature.  sign the hexed secret by user key
            let userSigner = SigningKey.init(privateKey: armoredUserKey,
                                             passphrase: userKeyPassphrase)
            /// sign addr passphrase
            let tokenSignature = try addrPassphrase.signDetached(signer: userSigner)

            /// build key matadata list
            let keylist: [[String: Any]] = [[
                "Fingerprint": armoredAddrKey.fingerprint,
                "SHA256Fingerprints": armoredAddrKey.sha256Fingerprint,
                "Primary": 1,
                "Flags": KeyFlags.signupKeyFlags.rawValue
            ]]
            
            /// encode to json format
            let jsonKeylist = keylist.json()
            
            /// sign detached. keylist.json signed by primary address key. on signup situation this is the address key we are going to submit.
            let addSigner = SigningKey.init(privateKey: armoredAddrKey,
                                            passphrase: addrPassphrase)
            let signed = try Sign.signDetached(signingKey: addSigner, plainText: jsonKeylist)
            let signedKeyList: [String: Any] = [
                "Data": jsonKeylist,
                "Signature": signed.value
            ]

            return AddressKey(addressId: addr.addressID, armoredKey: armoredAddrKey,
                              token: token, signature: tokenSignature,
                              signedKeyList: signedKeyList)
        }
        
        return GeneratedAccountKey(userKey: UserKey(armoredKey: armoredUserKey,
                                                    passwordSalt: newPasswordSalt,
                                                    password: userKeyPassphrase),
                                   addressKeys: addressKeys)
    }

    /// build up the setupkey route data
    /// - Parameters:
    ///   - password: NO NEED
    ///   - accountKey: generated account key
    ///   - modulus: srp modulus
    ///   - modulusId: modulus id
    /// - Returns: `AuthService.SetupKeysEndpoint`
    func setupSetupKeysRoute(password: String, accountKey: GeneratedAccountKey,
                             modulus: String, modulusId: String) throws -> AuthService.SetupKeysEndpoint {

        // for the login password needs to set 80 bits & srp auth use 80 bits
        let newSaltForKey: Data = PMNOpenPgp.randomBits(PasswordSaltSize.login.int32Bits)

        // generate new verifier
        guard let authForKey = try SrpAuthForVerifier(password, modulus, newSaltForKey) else {
            throw KeySetupError.cantHashPassword
        }
        
        let verifierForKey = try authForKey.generateVerifier(2048)

        let passwordAuth = PasswordAuth(modulusID: modulusId, salt: newSaltForKey.encodeBase64(), verifer: verifierForKey.encodeBase64())

        let addressData = accountKey.addressKeys.map { addressKey -> [String: Any] in
            let address: [String: Any] = [
                "AddressID": addressKey.addressId,
                "PrivateKey": addressKey.armoredKey.value,
                "Token": addressKey.token.value,
                "Signature": addressKey.signature.value,
                "SignedKeyList": addressKey.signedKeyList
            ]
            return address
        }
        return AuthService.SetupKeysEndpoint(addresses: addressData,
                                             privateKey: accountKey.userKey.armoredKey,
                                             keySalt: accountKey.userKey.passwordSalt.encodeBase64(),
                                             passwordAuth: passwordAuth)
    }    
}
