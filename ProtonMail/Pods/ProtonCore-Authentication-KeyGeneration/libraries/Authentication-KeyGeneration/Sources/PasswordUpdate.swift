//
//  PasswordUpdate.swift
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
import ProtonCore_DataModel
import Foundation
import ProtonCore_Authentication
import ProtonCore_Utilities
import ProtonCore_Hash

/// update password address/user  no UI yet. need get back to here when client need to migrate this
final class PasswordUpdate {

    struct UpdatedKeyResult {
        let saltOfNewPassword: Data
        let hashedNewPassword: String
        let updatedUserKeys: [Key]
        let originalUserKeys: [Key]
        let updatedAddresses: [Address]?
    }

    func updatePassword(userKeys: [Key], oldPassword: String, newPassword: String) throws -> UpdatedKeyResult {
        let saltOfNewPassword = try Crypto.random(byte: 16) // mailbox pwd need 128 bits
        let hashedNewPassword = PasswordHash.passphrase(newPassword, salt: saltOfNewPassword)
        let result = try Crypto.updateKeysPasswordIfPossible(keys: userKeys, currPass: Passphrase.init(value: oldPassword),
                                                             newPass: hashedNewPassword)
        let updatedKeys = result.filter({ $0.isUpdated })
        let originalKeys = result.filter({ !$0.isUpdated })
        return UpdatedKeyResult(saltOfNewPassword: saltOfNewPassword,
                                hashedNewPassword: hashedNewPassword.value,
                                updatedUserKeys: updatedKeys,
                                originalUserKeys: originalKeys,
                                updatedAddresses: nil)
    }
    
    func updatePasswordV1(userKeys: [Key], addressKeys: [Address], oldPassword: String, newPassword: String) throws -> UpdatedKeyResult {
        let saltOfNewPassword = try Crypto.random(byte: 16) // mailbox pwd need 128 bits
        let hashedNewPassword = PasswordHash.passphrase(newPassword, salt: saltOfNewPassword)
        let userKeyResult = try Crypto.updateKeysPasswordIfPossible(keys: userKeys, currPass: Passphrase.init(value: oldPassword),
                                                                    newPass: hashedNewPassword)
        let updatedUserKeys = userKeyResult.filter({ $0.isUpdated })
        let originalUserKeys = userKeyResult.filter({ $0.isUpdated })
        
        let addressKeyResult = try
        Crypto.updateAddrKeysPasswordIfPossible(addresses: addressKeys, currPass: Passphrase.init(value: oldPassword), newPass: hashedNewPassword)
        
        return UpdatedKeyResult(saltOfNewPassword: saltOfNewPassword,
                                hashedNewPassword: hashedNewPassword.value,
                                updatedUserKeys: updatedUserKeys,
                                originalUserKeys: originalUserKeys,
                                updatedAddresses: addressKeyResult)
    }
}

extension Crypto {
    
    /// update the key password if possible. this is mostly used for update user key pass,
    ///  in the real case, some accounts reset the password/key. they lost the password. but we will keep the old key inactive in our system.
    ///  when we update the keys and update those inactive keys the update passpharse might be failed.
    ///  on the web app, they have an interface to update the inative key if they remember the old password, but for the mobile, we only care if the first key update success or failed.
    /// - Parameters:
    ///   - keys: current keys. could by mulitple
    ///   - currPass: current pass. refer to mailbox password
    ///   - newPass: new pass
    /// - Returns: updated keys
    internal static func updateKeysPasswordIfPossible(keys: [Key], currPass: Passphrase, newPass: Passphrase) throws -> [Key] {
        var outKeys: [Key] = [Key]()
        for okey in keys {
            do {
                let nePrivateKey = try self.updatePassphrase(privateKey: ArmoredKey.init(value: okey.privateKey),
                                                             oldPassphrase: currPass, newPassphrase: newPass)
                let newK = Key(keyID: okey.keyID, privateKey: nePrivateKey.value, isUpdated: true)
                outKeys.append(newK)
            } catch { // if update passphrase failed. carry over the old keys
                let newK = Key(keyID: okey.keyID, privateKey: okey.privateKey)
                outKeys.append(newK)
            }
        }

        guard outKeys.count == keys.count else { // check if the count matches
            throw PasswordUpdateError.keyUpdateFailed
        }

        guard !outKeys.isEmpty && outKeys[0].isUpdated else { // check if the first key update succeeded
            throw PasswordUpdateError.keyUpdateFailed
        }

        /// double check the new passphrase could decrypt the key
        for iKey in outKeys {
            if iKey.isUpdated == false {
                continue
            }
            let result = iKey.privateKey.check(passphrase: newPass)
            guard result == true else {
                throw PasswordUpdateError.keyUpdateFailed
            }
        }
        return outKeys
    }
    
    /// we only care the first key update. logic same as `updateKeysPasswordIfPossible`
    internal static func updateAddrKeysPasswordIfPossible(addresses: [Address], currPass: Passphrase, newPass: Passphrase) throws -> [Address] {
        var outAddresses = [Address]()
        for addr in addresses {
            var outKeys = [Key]()
            for okey in addr.keys {
                do {
                    let newPrivateKey = try Crypto.updatePassphrase(privateKey: ArmoredKey.init(value: okey.privateKey),
                                                                    oldPassphrase: currPass,
                                                                    newPassphrase: newPass)
                    let newK = Key(keyID: okey.keyID,
                                   privateKey: newPrivateKey.value,
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
                throw PasswordUpdateError.keyUpdateFailed
            }
            
            guard !outKeys.isEmpty && outKeys[0].isUpdated else {
                throw PasswordUpdateError.keyUpdateFailed
            }
            
            for iKey in outKeys {
                if iKey.isUpdated == false {
                    continue
                }
                let result = iKey.privateKey.check(passphrase: newPass)
                guard result == true else {
                    throw PasswordUpdateError.keyUpdateFailed
                }
            }
            let newAddr = Address(addressID: addr.addressID,
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
            outAddresses.append(newAddr)
        }
        return outAddresses
    }
    
}
