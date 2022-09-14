//
//  AddressKeySetup.swift
//  ProtonCore-Authentication-KeyGeneration - Created on 05/23/2020
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
import ProtonCore_Hash
import ProtonCore_DataModel

final class AddressKeySetup {
    
    struct GeneratedAddressKey {
        /// armored key
        let armoredKey: ArmoredKey
        
        /// on phase 2. token used to encrypt address key
        let token: ArmoredMessage
        
        /// detached signaute.
        let signature: ArmoredSignature
        
        /// signed key matedata
        ///     simple:
        ///     let keylist: [[String: Any]] = [[
        ///         "Fingerprint": "key.fingerprint",  //address key fingerprint
        ///         "SHA256Fingerprints": "key.sha256fingerprint" // address key sha256Fingerprint,
        ///         "Primary": 1,    // 1 or 0   is it a primary key
        ///         "Flags": 3    // refer KeyFlags in DataModel
        ///     ]]
        ///
        ///     let signedKeyList: [String: Any] = [
        ///         "Data": JSON(keylist),      // encode key list to json
        ///         "Signature": SIGNED((JSON(keylist))    // user address key sign detached.
        ///     ]
        let signedKeyList: [String: Any]
    }
    
    /// use this funcetion to generate address key. secret is hex string of 32 bytes random data.
    func generateAddressKey(keyName: String, email: String, armoredUserKey: String, password: String, salt: Data) throws -> GeneratedAddressKey {
        guard !salt.isEmpty else {
            throw KeySetupError.invalidSalt
        }
        let userPrivateKey = ArmoredKey.init(value: armoredUserKey)
        let userKeyPassphrase = PasswordHash.passphrase(password, salt: salt)
        
        // Generate a 32 byte random secret and encode it in a 64 byte hex string
        let addrKeyPassphrase = PasswordHash.genAddrPassphrase()
        
        /// generate a new key.  id: address email.  passphrase: hexed secret (should be 64 bytes) with default key type
        let armoredAddrKey = try Generator.generateECCKey(email: email, passphase: addrKeyPassphrase)
        
        /// generate token.   token is hexed secret encrypted by `UserKey.publicKey`. Note: we don't need to inline sign
        let token = try addrKeyPassphrase.encrypt(publicKey: userPrivateKey)
        
        /// gnerenate a detached signature.  sign the hexed secret by
        let userSignerKey = SigningKey.init(privateKey: userPrivateKey,
                                            passphrase: userKeyPassphrase)
        let tokenSignature = try addrKeyPassphrase.signDetached(signer: userSignerKey)
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
        let addrSignerKey = SigningKey.init(privateKey: armoredAddrKey,
                                            passphrase: addrKeyPassphrase)
        let signed = try Sign.signDetached(signingKey: addrSignerKey, plainText: jsonKeylist)
        
        let signedKeyList: [String: Any] = [
            "Data": jsonKeylist,
            "Signature": signed.value
        ]
        return GeneratedAddressKey(armoredKey: armoredAddrKey,
                                   token: token,
                                   signature: tokenSignature,
                                   signedKeyList: signedKeyList)
    }
    
    func generateRandomSecret() -> String {
        let secret = PasswordHash.random(bits: PasswordSaltSize.addressKey.int32Bits) // generate random 32 bytes
        return HMAC.hexStringFromData(secret)
    }
    
    func setupCreateAddressKeyRoute(key: GeneratedAddressKey,
                                    addressId: String, isPrimary: Bool) throws -> AuthService.CreateAddressKeyEndpoint {
        
        return AuthService.CreateAddressKeyEndpoint(addressID: addressId,
                                                    privateKey: key.armoredKey,
                                                    signedKeyList: key.signedKeyList,
                                                    isPrimary: isPrimary,
                                                    token: key.token,
                                                    tokenSignature: key.signature)
    }
}
