//
//  OpenPGPExtension.swift
//  ProtonCore-PasswordChange - Created on 20.03.2024.
//
//  Copyright (c) 2024 Proton Technologies AG
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

extension Crypto {

    static func updateKeysPassword(_ oldKeys: [Key], oldPass: Passphrase, newPass: Passphrase) throws -> [Key] {
        var outKeys: [Key] = [Key]()
        for oldKey in oldKeys {
            do {
                let newPrivateKey = try self.updatePassphrase(
                    privateKey: ArmoredKey(value: oldKey.privateKey),
                    oldPassphrase: oldPass,
                    newPassphrase: newPass
                )
                let newKey = Key(keyID: oldKey.keyID, privateKey: newPrivateKey.value, isUpdated: true)
                outKeys.append(newKey)
            } catch {
                let newKey = Key(keyID: oldKey.keyID, privateKey: oldKey.privateKey)
                outKeys.append(newKey)
            }
        }

        guard outKeys.count == oldKeys.count else {
            throw UpdatePasswordError.keyUpdateFailed
        }

        guard outKeys.count > 0 && outKeys[0].isUpdated == true else {
            throw UpdatePasswordError.keyUpdateFailed
        }

        for updatedKey in outKeys {
            if !updatedKey.isUpdated { continue }
            let result = updatedKey.privateKey.check(passphrase: newPass)
            guard result else {
                throw UpdatePasswordError.keyUpdateFailed
            }
        }
        return outKeys
    }

    static func updateAddrKeysPassword(_ oldAddresses: [Address], oldPass: Passphrase, newPass: Passphrase) throws -> [Address] {
        var outAddresses = [Address]()
        for oldAddress in oldAddresses {
            var outKeys = [Key]()
            for oldKey in oldAddress.keys {
                do {
                    let newPrivateKey = try Crypto.updatePassphrase(privateKey: ArmoredKey(value: oldKey.privateKey),
                                                                    oldPassphrase: oldPass,
                                                                    newPassphrase: newPass)
                    let newKey = Key(keyID: oldKey.keyID,
                                     privateKey: newPrivateKey.value,
                                     keyFlags: oldKey.keyFlags,
                                     token: nil,
                                     signature: nil,
                                     activation: nil,
                                     active: oldKey.active,
                                     version: oldKey.version,
                                     primary: oldKey.primary,
                                     isUpdated: true)
                    outKeys.append(newKey)
                } catch {
                    let newKey = Key(keyID: oldKey.keyID,
                                     privateKey: oldKey.privateKey,
                                     keyFlags: oldKey.keyFlags,
                                     token: nil,
                                     signature: nil,
                                     activation: nil,
                                     active: oldKey.active,
                                     version: oldKey.version,
                                     primary: oldKey.primary,
                                     isUpdated: false)
                    outKeys.append(newKey)
                }
            }

            guard outKeys.count == oldAddress.keys.count else {
                throw UpdatePasswordError.keyUpdateFailed
            }

            guard outKeys.count > 0 && outKeys[0].isUpdated == true else {
                throw UpdatePasswordError.keyUpdateFailed
            }

            for updatedKey in outKeys {
                if !updatedKey.isUpdated { continue }
                let result = updatedKey.privateKey.check(passphrase: newPass)
                guard result else {
                    throw UpdatePasswordError.keyUpdateFailed
                }
            }
            let newAddress = Address(addressID: oldAddress.addressID,
                                     domainID: oldAddress.domainID,
                                     email: oldAddress.email,
                                     send: oldAddress.send,
                                     receive: oldAddress.receive,
                                     status: oldAddress.status,
                                     type: oldAddress.type,
                                     order: oldAddress.order,
                                     displayName: oldAddress.displayName,
                                     signature: oldAddress.signature,
                                     hasKeys: outKeys.isEmpty ? 0 : 1,
                                     keys: outKeys)
            outAddresses.append(newAddress)
        }

        guard outAddresses.count == oldAddresses.count else {
            throw UpdatePasswordError.keyUpdateFailed
        }

        return outAddresses
    }
}
