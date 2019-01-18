//
//  ProtectionStrategy.swift
//  ProtonMail - Created on 18/10/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import Security
import UICKeyChainStore

public protocol ProtectionStrategy {
    var keychain: UICKeyChainStore { get }
    func lock(value: Keymaker.Key) throws
    func unlock(cypherBits: Data) throws -> Keymaker.Key
}
public extension ProtectionStrategy {
    static func saveCyphertext(_ cypher: Data, in keychain: UICKeyChainStore) {
        keychain.setData(cypher, forKey: String(describing: Self.self))
    }
    static func removeCyphertext(from keychain: UICKeyChainStore) {
        keychain.removeItem(forKey: String(describing: Self.self))
    }
    func removeCyphertextFromKeychain() {
        self.keychain.removeItem(forKey: String(describing: Self.self))
    }
    static func getCypherBits(from keychain: UICKeyChainStore) -> Data? {
        return keychain.data(forKey: String(describing: Self.self))
    }
    func getCypherBits() -> Data? {
        return self.keychain.data(forKey: String(describing: Self.self))
    }
    
    static func generateRandomValue(length: Int) -> Keymaker.Key {
        var newKey = Array<UInt8>(repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, newKey.count, &newKey)
        guard status == 0 else {
            fatalError("failed to generate cryptographically secure value")
        }
        return newKey
    }
}
