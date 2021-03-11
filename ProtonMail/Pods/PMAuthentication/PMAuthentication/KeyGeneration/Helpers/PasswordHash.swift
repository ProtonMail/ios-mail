//
//  PasswordHash.swift
//  PMAuthentication
//
//  Created by Igor Kulman on 03.02.2021.
//

import Foundation

final class PasswordHash {
    enum PasswordError: Error {
        case hashEmpty
        case hashEmptyEncode
        case hashSizeWrong
    }

    static func hashPassword(_ password: String, salt: Data) -> String {
        let byteArray = NSMutableData()
        byteArray.append(salt)
        let source = NSData(data: byteArray as Data) as Data
        let encodedSalt = JKBCrypt.based64DotSlash(source)
        do {
            let out = try bcrypt(password, salt: encodedSalt)
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

    static func bcrypt(_ password: String, salt: String) throws -> String {
        let real_salt = "$2a$10$" + salt

        //backup plan when native bcrypt return empty string
        if let out = JKBCrypt.hashPassword(password, withSalt: real_salt), !out.isEmpty {
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
}
