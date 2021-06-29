//
//  PasswordHash.swift
//  PMAuthentication
//
//  Created by Igor Kulman on 03.02.2021.
//

import Foundation
import OpenPGP
import Crypto


final public class PasswordHash {
    enum PasswordError: Error {
        case hashEmpty
        case hashEmptyEncode
        case hashSizeWrong
    }
    
    public static func random(bits: Int32) -> Data {
        let salt : Data = PMNOpenPgp.randomBits(bits)
        return salt
    }

    public static func hashPassword(_ password: String, salt: Data) -> String {
        
        /// This Mutable data process looks usless.
        let byteArray = NSMutableData()
        byteArray.append(salt)
        let source = NSData(data: byteArray as Data) as Data
        do {
            let out = try bcrypt(password, salt: source)
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
    
    static func bcrypt(_ password :String, salt :Data) throws -> String {
        let encodedSalt = JKBCrypt.based64DotSlash(salt)
        let real_salt = "$2a$10$" + encodedSalt
        
        let out_hash = PMNBCryptHash.hashString(password, salt: real_salt)
        if !out_hash.isEmpty {
            let size = out_hash.count
            if size > 4 {
                let index = out_hash.index(out_hash.startIndex, offsetBy: 4)
                return "$2y$" + String(out_hash[index...])
            }
        }
        
        //---- backup plan
        var error: NSError?
        let passSlic = password.data(using: .utf8)
        let out = SrpMailboxPassword(passSlic, salt, &error)
        if let err = error {
            throw err
        }
        
        guard let outSlic = out, let outHash = String.init(data: outSlic, encoding: .utf8) else {
            throw PasswordError.hashEmpty
        }
        let size = outHash.count
        if size > 4 {
            let index = outHash.index(outHash.startIndex, offsetBy: 4)
            return "$2y$" + String(outHash[index...])
        } else {
            throw PasswordError.hashSizeWrong
        }
    }
}
