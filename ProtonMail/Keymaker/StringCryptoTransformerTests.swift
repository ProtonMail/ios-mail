//
//  StringCryptoTransformerTests.swift
//  ProtonMail - Created on 15/11/2018.
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
@testable import Keymaker

class StringCryptoTransformerTests: XCTestCase {
    private func makeKey() -> Keymaker.Key {
        var key = Array<UInt8>(repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, key.count, &key)
        if status != 0 {
            XCTAssert(false, "failed to create cryptographically secure key")
        }
        return key
    }
    
    func testStringExample() {
        let transformer = StringCryptoTransformer(key: self.makeKey())
        let name = "Santa Blanca"
        
        guard let encrypted = transformer.transformedValue(name) as? NSData else {
            XCTFail()
            return
        }
        guard let decrypted = transformer.reverseTransformedValue(encrypted) as? String else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(decrypted, name)
    }
    
    func testEmptyExample() {
        let transformer = StringCryptoTransformer(key: self.makeKey())
        let name = ""
        
        guard let encrypted = transformer.transformedValue(name) as? NSData else {
            XCTFail()
            return
        }
        guard let decrypted = transformer.reverseTransformedValue(encrypted) as? String else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(decrypted, name)
    }

}
