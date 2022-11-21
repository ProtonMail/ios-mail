//
//  LoginService+Crypto.swift
//  ProtonCore-Login - Created on 12/11/2020.
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
import Foundation
import ProtonCore_DataModel
import ProtonCore_Utilities

extension LoginService {
    // Code take from Drive
    // TODO:: need to deperate this function. go lib has low performance than the other file we have 
    func makePassphrases(salts: [KeySalt], mailboxPassword: String) -> Result<[String: String], Error> {
        var error: NSError?

        let passphrases = salts.filter {
            $0.keySalt != nil
        }.map { salt -> (String, String) in
            let keySalt = salt.keySalt!
            
            let passSlice = mailboxPassword.data(using: .utf8)

            let saltPackage = Data(base64Encoded: keySalt, options: NSData.Base64DecodingOptions(rawValue: 0))
            let passphraseSlice = SrpMailboxPassword(passSlice, saltPackage, &error)
            
            let passphraseUncut = String.init(data: passphraseSlice!, encoding: .utf8)
            // by some internal reason of go-srp, output will be 60 characters but we need only last 31 of them
            let passphrase = passphraseUncut!.suffix(31)
            
            return (salt.ID, String(passphrase))
        }

        if let error = error {
            return .failure(error)
        }

        return .success(Dictionary(passphrases, uniquingKeysWith: { one, _ in one }))
    }

    func validateMailboxPassword(passphrases: ([String: String]), userKeys: [Key]) -> Bool {
        var isValid = false
  
        // new keys - user keys
        passphrases.forEach { keyID, passphrase in
            userKeys.filter { $0.keyID == keyID && $0.primary == 1 }
            .map(\.privateKey)
            .forEach { privateKey in
                var error: NSError?
                let armored = CryptoNewKeyFromArmored(privateKey, &error)

                do {
                    try armored?.unlock(passphrase.utf8)
                    isValid = true
                } catch {
                    // do nothing
                }
            }
        }

        return isValid
    }
}
