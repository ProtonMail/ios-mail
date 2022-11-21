//
//  Crypto+Keys.swift
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
import GoLibs

import ProtonCore_DataModel

/// Array<Key> extensions
extension Array where Element: Key {
    
    /// loop and combin all keys in binary
    public var toArmoredPrivateKeys: [ArmoredKey] {
        return self.map { item in
            ArmoredKey.init(value: item.privateKey)
        }
    }
}

extension Key {
    
    /// Key_1_2  the func to get the real passphrase that can decrypt the body. TODO:: add unit tests
    /// - Parameters:
    ///   - userBinKeys: user keys need to unarmed to binary
    ///   - mailboxPassphrase: user password hashed with the key salt
    /// - Throws: crypt exceptions
    /// - Returns: passphrase
    public func passphrase(userPrivateKeys: [ArmoredKey], mailboxPassphrase: Passphrase) throws -> Passphrase {
        guard let token = self.token, let signature = self.signature else {
            return mailboxPassphrase
        }
        
        let plainToken: String
        do {
            var userkeys: [DecryptionKey] = []
            for key in userPrivateKeys {
                userkeys.append(DecryptionKey.init(privateKey: key,
                                                   passphrase: mailboxPassphrase))
            }
            plainToken = try Decryptor.decrypt(decryptionKeys: userkeys, encrypted: ArmoredMessage.init(value: token))
        } catch {
            throw error
        }
        
        let verification = try Sign.verifyDetached(signature: ArmoredSignature.init(value: signature),
                            plainText: plainToken, verifierKeys: userPrivateKeys)

        if verification != true {
            throw CryptoError.tokenSignatureVerificationFailed
        }
        return Passphrase.init(value: plainToken)
    }
    
    public func passphrase(userKeys: [Key], mailboxPassphrase: String) throws -> Passphrase {
        return try self.passphrase(userPrivateKeys: userKeys.toArmoredPrivateKeys,
                                   mailboxPassphrase: Passphrase.init(value: mailboxPassphrase))
    }
}
