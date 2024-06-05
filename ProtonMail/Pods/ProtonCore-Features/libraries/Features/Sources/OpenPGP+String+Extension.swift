//
//  OpenPGP+String+Extension.swift
//  ProtonCore-Features - Created on 22.05.2018.
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

import Foundation
import ProtonCoreAuthentication
import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel

// MARK: - OpenPGP String extension

extension String {

    @available(*, deprecated, message: "Please use armored key", renamed: "verifyMessage(userKeys:passphrase:addrKeys:verifier:time:)")
    func verifyMessage(verifier: [Data], binKeys: [Data], passphrase: String, time: Int64) throws -> ExplicitVerifyMessage {
        return try Crypto().decryptVerifyNonOptional(encrypted: self, publicKey: verifier,
                                                     privateKey: binKeys, passphrase: passphrase, verifyTime: time)
    }

    @available(*, deprecated, message: "Please use armored key", renamed: "verifyMessage(userKeys:passphrase:addrKeys:verifier:time:)")
    func verifyMessage(verifier: [Data], userKeys: [Data], keys: [Key], passphrase: String, time: Int64) throws -> ExplicitVerifyMessage? {
        var firstError: Error?
        for key in keys {
            do {
                let addressKeyPassphrase = try key.passphrase(userBinKeys: userKeys, mailboxPassphrase: passphrase)
                return try Crypto().decryptVerifyNonOptional(encrypted: self,
                                                             publicKey: verifier,
                                                             privateKey: key.privateKey,
                                                             passphrase: addressKeyPassphrase,
                                                             verifyTime: time)
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

    func verifyMessage(userKeys: [ArmoredKey], passphrase: Passphrase, addrKeys: [Key],
                       verifiers: [ArmoredKey], time: Int64) throws -> VerifiedString {
        guard !addrKeys.isEmpty else {
            throw CryptoError.emptyAddressKeys
        }

        var firstError: Error?
        for key in addrKeys {
            do {
                let addressKeyPassphrase = try key.passphrase(userPrivateKeys: userKeys,
                                                              mailboxPassphrase: passphrase)

                let decryptionKey = DecryptionKey.init(privateKey: ArmoredKey.init(value: key.privateKey),
                                                       passphrase: addressKeyPassphrase)
                return try Decryptor.decryptAndVerify(decryptionKeys: [decryptionKey],
                                                      value: ArmoredMessage.init(value: self),
                                                      verificationKeys: verifiers)
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
            }
        }
        if let error = firstError {
            throw error
        }

        // logically. code won't run here. except for the address key is empty
        return .unverified("", CryptoError.decryptAndVerifyFailed)
    }

    public func encrypt(withKey key: Key, userKeys: [Data], mailbox_pwd: String) throws -> String? {
        let addressKeyPassphrase = try key.passphrase(userPrivateKeys: userKeys.toArmored,
                                                      mailboxPassphrase: Passphrase.init(value: mailbox_pwd))
        let signerKey = SigningKey.init(privateKey: ArmoredKey.init(value: key.privateKey),
                                        passphrase: addressKeyPassphrase)
        return try Encryptor.encrypt(publicKey: ArmoredKey.init(value: key.publicKey),
                                     cleartext: self, signerKey: signerKey).value
    }

    internal func decryptBody(keys: [Key], passphrase: Passphrase) throws -> String? {
        var firstError: Error?
        for key in keys {
            do {
                return try self.decryptMessageWithSingleKeyNonOptional(ArmoredKey.init(value: key.privateKey),
                                                                       passphrase: passphrase)
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
                // PMLog.D(error.localizedDescription)
            }
        }

        if let error = firstError {
            throw error
        }
        return nil
    }

    internal func decryptBody(keys: [Key], userKeys: [Data], passphrase: Passphrase) throws -> String? {
        var firstError: Error?
        for key in keys {
            do {
                let addressKeyPassphrase = try key.passphrase(userPrivateKeys: userKeys.toArmored,
                                                              mailboxPassphrase: passphrase)
                return try self.decryptMessageWithSingleKeyNonOptional(ArmoredKey.init(value: key.privateKey),
                                                                       passphrase: addressKeyPassphrase)
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
