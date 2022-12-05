//
//  PasswordHash.swift
//  ProtonCore-Authentication-KeyGeneration - Created on 03.02.2021.
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
import OpenPGP
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
import ProtonCore_Hash

public final class PasswordHash {
    enum PasswordError: Error {
        case hashEmpty
        case hashEmptyEncode
        case hashSizeWrong
    }
    
    public static func random(bits: Int32) -> Data {
        let salt: Data = PMNOpenPgp.randomBits(bits)
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
    
    public static func passphrase(_ password: String, salt: Data) -> Passphrase {
        return .init(value: self.hashPassword(password, salt: salt))
    }
    
    /// Generate a 32 byte random secret and encode it in a 64 byte hex string
    /// - Returns: Passphrase
    public static func genAddrPassphrase() -> Passphrase {
        /// generate address key secret size 32 bytes or 256 bits
        let secret = PasswordHash.random(bits: PasswordSaltSize.addressKey.int32Bits) // generate random 32 bytes
        /// hex string of secret data
        let hexSecret = HMAC.hexStringFromData(secret)
        assert(hexSecret.count == 64)
        return Passphrase.init(value: hexSecret)
    }
    
    static func bcrypt(_ password: String, salt: Data) throws -> String {
        var error: NSError?
        let passSlice = password.data(using: .utf8)
        let out = SrpMailboxPassword(passSlice, salt, &error)
        if let err = error {
            throw err
        }
        guard let outSlice = out, let outHash = String.init(data: outSlice, encoding: .utf8) else {
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
