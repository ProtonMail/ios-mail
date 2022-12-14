//
//  AddressKeyActivation.swift
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

import GoLibs
import ProtonCore_Crypto
import OpenPGP
import Foundation
import ProtonCore_Authentication
import ProtonCore_DataModel
import ProtonCore_Utilities
import ProtonCore_Hash

final class AddressKeyActivation {
    
    enum KeyActivationError: Error {
        case noUserKey
    }
    
    /// V1 key activation flow
    /// - Parameters:
    ///   - user: user object. we will use the user.keys
    ///   - address: addresses
    ///   - mailboxPassword: mailbox password
    /// - Returns: activation endpoint
    func activeAddressKeysV1(user: User, address: Address, mailboxPassword: String) throws -> AuthService.KeyActivationEndpointV1? {
        for index in address.keys.indices {
            let key = address.keys[index]
            if let activation = key.activation {
                
                guard let firstUserKey = user.keys.first else {
                    throw KeyActivationError.noUserKey
                }
                
                let armoredUserKey = ArmoredKey.init(value: firstUserKey.privateKey)
                let mailboxPassphrase = Passphrase.init(value: mailboxPassword)
                
                let token = try activation.decryptMessageWithSingleKeyNonOptional(armoredUserKey, passphrase: mailboxPassphrase)
                
                let newPrivateKey = try Crypto.updatePassphrase(privateKey: ArmoredKey.init(value: key.privateKey),
                                                                oldPassphrase: Passphrase.init(value: token),
                                                                newPassphrase: mailboxPassphrase)
                let keylist: [[String: Any]] = [[
                    "Fingerprint": key.privateKey.fingerprint,
                    "Primary": 1,
                    "Flags": KeyFlags.signupKeyFlags.rawValue
                ]]
                let jsonKeylist = keylist.json()
                
                let signer = SigningKey.init(privateKey: newPrivateKey,
                                             passphrase: mailboxPassphrase)
                let signed = try Sign.signDetached(signingKey: signer, plainText: jsonKeylist)
                let signedKeyList: [String: Any] = [
                    "Data": jsonKeylist,
                    "Signature": signed.value
                ]
                let api = AuthService.KeyActivationEndpointV1(addrID: key.keyID, privKey: newPrivateKey.value, signedKL: signedKeyList)
                return api
            }
        }
        
        return nil
    }
    
    /// V2 key activation flow
    /// - Parameters:
    ///   - user: User
    ///   - address: address
    ///   - hashedPassword: hased password
    /// - Returns: api endpoint
    func activeAddressKeys(user: User, address: Address, mailboxPassword: String) throws -> AuthService.KeyActivationEndpoint? {
        for index in address.keys.indices {
            let key = address.keys[index]
            if let activation = key.activation {
                
                guard let firstUserKey = user.keys.first else {
                    throw KeyActivationError.noUserKey
                }
                
                let armoredUserKey = ArmoredKey.init(value: firstUserKey.privateKey)
                let mailboxPassphrase = Passphrase.init(value: mailboxPassword)
                
                let clearToken = try activation.decryptMessageWithSingleKeyNonOptional(armoredUserKey, passphrase: mailboxPassphrase)
                                
                // generate random addr passphrase
                let newPassphrase = PasswordHash.genAddrPassphrase()
                
                // use the new hexed secret to update the address private key
                let updatedPrivateKey = try Crypto.updatePassphrase(privateKey: ArmoredKey.init(value: key.privateKey),
                                                                    oldPassphrase: Passphrase.init(value: clearToken),
                                                                    newPassphrase: newPassphrase)
                /// encrypt token
                let encToken = try newPassphrase.encrypt(publicKey: armoredUserKey)
                /// gnerenate a detached signature.  sign the hexed secret by
                let signer = SigningKey.init(privateKey: armoredUserKey,
                                             passphrase: mailboxPassphrase)
                let tokenSignature = try newPassphrase.signDetached(signer: signer)
                let keyFlags: KeyFlags
                if address.type == .externalAddress {
                    keyFlags = .signupExternalKeyFlags
                } else {
                    keyFlags = .signupKeyFlags
                }
                let keylist: [[String: Any]] = [[
                    "Fingerprint": updatedPrivateKey.fingerprint,
                    "SHA256Fingerprints": updatedPrivateKey.sha256Fingerprint,
                    "Primary": 1,
                    "Flags": keyFlags.rawValue
                ]]
                let jsonKeylist = keylist.json()
                
                let updatedSigner = SigningKey.init(privateKey: updatedPrivateKey,
                                                    passphrase: newPassphrase)
                let signed = try Sign.signDetached(signingKey: updatedSigner, plainText: jsonKeylist)
                let signedKeyList: [String: Any] = [
                    "Data": jsonKeylist,
                    "Signature": signed.value
                ]
                
                let api = AuthService.KeyActivationEndpoint(addrID: key.keyID, privKey: updatedPrivateKey.value, signedKL: signedKeyList,
                                                            token: encToken.value, signature: tokenSignature.value, primary: key.primary)
                return api
            }
        }
        
        return nil
    }
}
