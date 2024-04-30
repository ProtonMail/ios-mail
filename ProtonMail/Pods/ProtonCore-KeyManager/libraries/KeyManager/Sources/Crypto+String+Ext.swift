//
//  Crypto+String.swift
//  ProtonCore-Crypto - Created on 9/11/19.
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
import ProtonCoreCrypto
import ProtonCoreDataModel

extension String {

    @available(*, deprecated, message: "Please use the non-optional variant")
    public func verifyMessage(verifier: [Data],
                              userKeys: [Data],
                              keys: [Key],
                              passphrase: String,
                              time: Int64) throws -> ExplicitVerifyMessage? {
        do {
            return try verifyMessageNonOptional(verifier: verifier, userKeys: userKeys, keys: keys, passphrase: passphrase, time: time)
        } catch CryptoError.messageCouldNotBeDecryptedWithExplicitVerification {
            return nil
        } catch {
            throw error
        }
    }

    public func verifyMessageNonOptional(verifier: [Data],
                                         userKeys: [Data],
                                         keys: [Key],
                                         passphrase: String,
                                         time: Int64) throws -> ExplicitVerifyMessage {
        var firstError: Error?
        for key in keys {
            do {
                let addressKeyPassphrase = try key.passphrase(userPrivateKeys: userKeys.toArmored,
                                                              mailboxPassphrase: Passphrase.init(value: passphrase))
                return try Crypto().decryptVerifyNonOptional(encrypted: self,
                                                             publicKey: verifier,
                                                             privateKey: key.privateKey,
                                                             passphrase: addressKeyPassphrase.value,
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
        throw CryptoError.messageCouldNotBeDecryptedWithExplicitVerification
    }
}
