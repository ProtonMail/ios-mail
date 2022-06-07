//
//  OpenPGPExtension.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import Crypto
import OpenPGP
import ProtonCore_DataModel

extension Crypto {

    static func updateKeysPassword(_ old_keys: [Key], old_pass: String, new_pass: String ) throws -> [Key] {
        var outKeys: [Key] = [Key]()
        for okey in old_keys {
            do {
                let new_private_key = try self.updatePassphrase(privateKey: okey.privateKey, oldPassphrase: old_pass, newPassphrase: new_pass)
                let newK = Key(keyID: okey.keyID, privateKey: new_private_key, isUpdated: true)
                outKeys.append(newK)
            } catch {
                let newK = Key(keyID: okey.keyID, privateKey: okey.privateKey)
                outKeys.append(newK)
            }
        }

        guard outKeys.count == old_keys.count else {
            throw UpdatePasswordError.keyUpdateFailed.error
        }

        guard outKeys.count > 0 && outKeys[0].isUpdated == true else {
            throw UpdatePasswordError.keyUpdateFailed.error
        }

        for u_k in outKeys {
            if u_k.isUpdated == false {
                continue
            }
            let result = u_k.privateKey.check(passphrase: new_pass)
            guard result == true else {
                throw UpdatePasswordError.keyUpdateFailed.error
            }
        }
        return outKeys
    }

    static func updateAddrKeysPassword(_ old_addresses: [Address], old_pass: String, new_pass: String ) throws -> [Address] {
        var out_addresses = [Address]()
        for addr in old_addresses {
            var outKeys = [Key]()
            for okey in addr.keys {
                do {
                    let new_private_key = try Crypto.updatePassphrase(privateKey: okey.privateKey,
                                                                      oldPassphrase: old_pass,
                                                                      newPassphrase: new_pass)
                    let newK = Key(keyID: okey.keyID,
                                   privateKey: new_private_key,
                                   keyFlags: okey.keyFlags,
                                   token: nil,
                                   signature: nil,
                                   activation: nil,
                                   active: okey.active,
                                   version: okey.version,
                                   primary: okey.primary,
                                   isUpdated: true)
                    outKeys.append(newK)
                } catch {
                    let newK = Key(keyID: okey.keyID,
                                   privateKey: okey.privateKey,
                                   keyFlags: okey.keyFlags,
                                   token: nil,
                                   signature: nil,
                                   activation: nil,
                                   active: okey.active,
                                   version: okey.version,
                                   primary: okey.primary,
                                   isUpdated: false)
                    outKeys.append(newK)
                }
            }

            guard outKeys.count == addr.keys.count else {
                throw UpdatePasswordError.keyUpdateFailed.error
            }

            guard outKeys.count > 0 && outKeys[0].isUpdated == true else {
                throw UpdatePasswordError.keyUpdateFailed.error
            }

            for u_k in outKeys {
                if u_k.isUpdated == false {
                    continue
                }
                let result = u_k.privateKey.check(passphrase: new_pass)
                guard result == true else {
                    throw UpdatePasswordError.keyUpdateFailed.error
                }
            }
            let new_addr = Address(addressID: addr.addressID,
                                   domainID: addr.domainID,
                                   email: addr.email,
                                   send: addr.send,
                                   receive: addr.receive,
                                   status: addr.status,
                                   type: addr.type,
                                   order: addr.order,
                                   displayName: addr.displayName,
                                   signature: addr.signature,
                                   hasKeys: outKeys.isEmpty ? 0 : 1,
                                   keys: outKeys)
            out_addresses.append(new_addr)
        }

        guard out_addresses.count == old_addresses.count else {
            throw UpdatePasswordError.keyUpdateFailed.error
        }

        return out_addresses
    }

}

protocol AttachmentDecryptor {
    func decryptAttachment(keyPacket: Data,
                           dataPacket: Data,
                           privateKey: String,
                           passphrase: String) throws -> Data?
}

extension Crypto: AttachmentDecryptor {}

extension Data {
    func decryptAttachment(keyPackage: Data,
                           userKeys: [Data],
                           passphrase: String,
                           keys: [Key],
                           attachmentDecryptor: AttachmentDecryptor = Crypto()) throws -> Data? {
        var firstError: Error?
        for key in keys {
            do {
                let addressKeyPassphrase = try Crypto.getAddressKeyPassphrase(userKeys: userKeys,
                                                                              passphrase: passphrase,
                                                                              key: key)
                if let decryptedAttachment = try attachmentDecryptor.decryptAttachment(keyPacket: keyPackage,
                                                                                        dataPacket: self,
                                                                                        privateKey: key.privateKey,
                                                                                        passphrase: addressKeyPassphrase) {
                    return decryptedAttachment
                } else {
                    throw Crypto.CryptoError.unexpectedNil
                }
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
            }
        }
        if let error = firstError {
            throw error
        }
        return nil
    }

    func decryptAttachment(_ keyPackage: Data, passphrase: String, privKeys: [Data]) throws -> Data? {
        return try Crypto().decryptAttachment(keyPacket: keyPackage, dataPacket: self, privateKey: privKeys, passphrase: passphrase)
    }

    // key packet part
    func getSessionFromPubKeyPackage(_ passphrase: String, privKeys: [Data]) throws -> SymmetricKey? {
        return try Crypto().getSession(keyPacket: self, privateKeys: privKeys, passphrase: passphrase)
    }

    // key packet part
    func getSessionFromPubKeyPackage(addrPrivKey: String, passphrase: String) throws -> SymmetricKey? {
        return try Crypto().getSession(keyPacket: self, privateKey: addrPrivKey, passphrase: passphrase)
    }

    // key packet part
    func getSessionFromPubKeyPackage(userKeys: [Data], passphrase: String, keys: [Key]) throws -> SymmetricKey? {
        var firstError: Error?
        for key in keys {
            do {
                let addressKeyPassphrase = try Crypto.getAddressKeyPassphrase(userKeys: userKeys,
                                                                              passphrase: passphrase,
                                                                              key: key)
                if let sessionKey = try Crypto().getSession(keyPacket: self,
                                                            privateKey: key.privateKey,
                                                            passphrase: addressKeyPassphrase) {
                    return sessionKey
                } else {
                    throw Crypto.CryptoError.unexpectedNil
                }
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
            }
        }
        if let error = firstError {
            throw error
        }
        return nil
    }
}
