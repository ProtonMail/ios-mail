//
//  PasswordUtils.swift
//  Proton Mail - Created on 9/28/16.
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
import OpenPGP
import ProtonCore_Authentication
import ProtonCore_Authentication_KeyGeneration
import ProtonCore_Hash

enum PasswordError: Error {
    case hashEmpty
    case hashSizeWrong
}

final class PasswordUtils {
    fileprivate static func bcrypt(_ password: String, salt: String) throws -> String {
        let real_salt = "$2a$10$" + salt
        let out_hash = PMNBCrypt(password: password, salt: real_salt)
        if !out_hash.isEmpty {
            let size = out_hash.count
            if size > 4 {
                let index = out_hash.index(out_hash.startIndex, offsetBy: 4)
                return "$2y$" + String(out_hash[index...])
            }
        }

        /* TODO NOTE for Feng: migrate this code to ProtonCore's version of bcrypt */
        if let out = real_salt.data(using: .utf8).map({ PasswordHash.hashPassword(password, salt: $0) }), !out.isEmpty {
            let size = out.count
            if size > 4 {
                let index = out.index(out.startIndex, offsetBy: 4)
                return "$2y$" + String(out[index...])
            } else {
                throw PasswordError.hashSizeWrong
            }
        }
        throw PasswordError.hashEmpty
    }

    fileprivate static func bcrypt_string(_ password: String, salt: String) throws -> String {
        let b = try bcrypt(password, salt: salt)
        return b
    }

    static func getMailboxPassword(_ password: String, salt: Data) -> String {
        let byteArray = NSMutableData()
        byteArray.append(salt)
        let source = NSData(data: byteArray as Data) as Data
        let encodedSalt = JKBCrypt.based64DotSlash(source)
        do {
            let out = try bcrypt_string(password, salt: encodedSalt)
            let index = out.index(out.startIndex, offsetBy: 29)
            let outStr = String(out[index...])
            return outStr
        } catch PasswordError.hashEmpty {
            // check error
        } catch PasswordError.hashSizeWrong {
            // check error
        } catch {
            // check error
        }
        return ""

    }
}
