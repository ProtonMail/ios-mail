//
//  HelperHashTests.swift
//  PMAuthenticationTests - Created on 03/16/2021.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
import Crypto
import OpenPGP

@testable import ProtonCore_Authentication

class HelperHashTests: XCTestCase {
    
    func testOpenPGPRandom() {
        measure {
            for _ in 0 ..< 1000 {
                _ = PMNOpenPgp.randomBits(128)
            }
        }
    }
    
    func testCryptoRandom() {
        measure {
            for _ in 0 ..< 1000 {
               _ = CryptoRandomToken(10, nil)
            }
        }
    }
    
    func testOpenPGPBCrypt() {
        
        let testpassword = "this is a test password"
        let randomSalt = PasswordHash.random(bits: 128)
        
        let byteArray = NSMutableData()
        byteArray.append(randomSalt)
        let source = NSData(data: byteArray as Data) as Data
        let encodedSalt = JKBCrypt.based64DotSlash(source)
        let real_salt = "$2a$10$" + encodedSalt
        measure {
            for _ in 0 ..< 20 {
                _ = PMNBCryptHash.hashString(testpassword, salt: real_salt)
            }
        }
    }
    
    func testCryptoBCrypt() {
        let testpassword = "this is a test password"
        let randomSalt = PasswordHash.random(bits: 128)
        
        let byteArray = NSMutableData()
        byteArray.append(randomSalt)
        let source = NSData(data: byteArray as Data) as Data
        measure {
            for _ in 0 ..< 20 {
                var error: NSError?
                let passwordSlic = testpassword.data(using: .utf8)
                _ = SrpMailboxPassword(passwordSlic, source, &error)
            }
        }
    }
    
    func testAutoAuthRefreshRaceConditaion() {
        let testpassword = "this is a test password"
        let randomSalt = PasswordHash.random(bits: 128)
        
        let byteArray = NSMutableData()
        byteArray.append(randomSalt)
        let source = NSData(data: byteArray as Data) as Data
        let encodedSalt = JKBCrypt.based64DotSlash(source)
        let real_salt = "$2a$10$" + encodedSalt
        let out = PMNBCryptHash.hashString(testpassword, salt: real_salt)
        var index = out.index(out.startIndex, offsetBy: 4)
        let leftPwd = "$2y$" + String(out[index...])
        
        var error: NSError?
        let testpasswordSlic = testpassword.data(using: .utf8)
        let outSlic = SrpMailboxPassword(testpasswordSlic, source, &error)
        XCTAssertNotNil(outSlic)
        let outString = String.init(data: outSlic!, encoding: .utf8)
        XCTAssertNotNil(outString)
        index = outString!.index(outString!.startIndex, offsetBy: 4)
        let rightPwd = "$2y$" + String(outString![index...])
        XCTAssertEqual(leftPwd, rightPwd)
    }
}
