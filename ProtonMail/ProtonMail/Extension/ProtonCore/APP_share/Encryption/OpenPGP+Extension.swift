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
import ProtonCoreCrypto
import ProtonCoreDataModel

protocol AttachmentDecryptor {
    func decryptAttachmentNonOptional(keyPacket: Data,
                                      dataPacket: Data,
                                      privateKey: String,
                                      passphrase: String) throws -> Data
}

extension Crypto: AttachmentDecryptor {}

extension Data {
    func decryptAttachment(keyPackage: Data,
                           userKeys: [ArmoredKey],
                           passphrase: Passphrase,
                           keys: [Key],
                           attachmentDecryptor: AttachmentDecryptor = Crypto()) throws -> Data? {
        var firstError: Error?
        for key in keys {
            do {
                let addressKeyPassphrase = try key.passphrase(userPrivateKeys: userKeys, mailboxPassphrase: passphrase)
                let decryptedAttachment = try attachmentDecryptor.decryptAttachmentNonOptional(
                    keyPacket: keyPackage,
                    dataPacket: self,
                    privateKey: key.privateKey,
                    passphrase: addressKeyPassphrase.value
                )
                return decryptedAttachment
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

    // key packet part
    func getSessionFromPubKeyPackage(userKeys: [ArmoredKey], passphrase: Passphrase, keys: [Key]) throws -> SessionKey? {
        var firstError: Error?
        for key in keys {
            do {
                let addressKeyPassphrase = try key.passphrase(userPrivateKeys: userKeys, mailboxPassphrase: passphrase)
                let decryptionKey = DecryptionKey(
                    privateKey: ArmoredKey(value: key.privateKey),
                    passphrase: addressKeyPassphrase
                )
                let sessionKey = try Decryptor.decryptSessionKey(decryptionKeys: [decryptionKey], keyPacket: self)
                return sessionKey
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
