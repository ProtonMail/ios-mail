//
//  PinProtection.swift
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
import Crypto
import UICKeyChainStore

public struct PinProtection: ProtectionStrategy {
    public let keychain: UICKeyChainStore
    private let pin: String
    
    public init(pin: String, keychain: UICKeyChainStore) {
        self.pin = pin
        self.keychain = keychain
    }
    
    private static let saltKeychainKey = String(describing: PinProtection.self) + ".salt"
    private static let numberOfIterations: Int = 2000 // bigger number works very slow on iPhone 5S
    enum Errors: Error {
        case saltNotFound
        case failedToDeriveKey
    }
    
    public func lock(value: Keymaker.Key) throws {
        let salt = PinProtection.generateRandomValue(length: 8)
        var error: NSError?
        guard let ethemeralKey = CryptoDeriveKey(pin, Data(bytes: salt), &error) else {
            throw error ?? Errors.failedToDeriveKey
        }
        let locked = try Locked<Keymaker.Key>(clearValue: value, with: ethemeralKey.bytes)
        
        PinProtection.saveCyphertext(locked.encryptedValue, in: self.keychain)
        self.keychain.setData(Data(bytes: salt), forKey: PinProtection.saltKeychainKey)
    }
    
    public func unlock(cypherBits: Data) throws -> Keymaker.Key {
        guard let salt = self.keychain.data(forKey: PinProtection.saltKeychainKey) else {
            throw Errors.saltNotFound
        }
        var error: NSError?
        guard let ethemeralKey = CryptoDeriveKey(pin, salt, &error) else {
            throw error ?? Errors.failedToDeriveKey
        }
        do {
            let locked = Locked<Keymaker.Key>.init(encryptedValue: cypherBits)
            return try locked.unlock(with: ethemeralKey.bytes)
        } catch let error {
            print(error)
            throw error
        }
    }
    
    public static func removeCyphertext(from keychain: UICKeyChainStore) {
        (self as ProtectionStrategy.Type).removeCyphertext(from: keychain)
        keychain.removeItem(forKey: self.saltKeychainKey)
    }
}

extension Data {
    var bytes: Array<UInt8> {
        return Array<UInt8>(self)
    }
}
