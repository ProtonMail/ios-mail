//
//  Locked.swift
//  ProtonMail - Created on 15/10/2018.
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

public struct Locked<T> {
    public enum Errors: Error {
        case failedToTurnValueIntoData
        case keyDoesNotMatch
        case failedToEncrypt
        case failedToDecrypt
    }
    public private(set) var encryptedValue: Data
    
    public init(encryptedValue: Data) {
        self.encryptedValue = encryptedValue
    }
    
    public init(clearValue: T, with encryptor: ((T) throws -> Data)) throws  {
        self.encryptedValue = try encryptor(clearValue)
    }
    
    public func unlock(with decryptor: ((Data) throws ->T)) throws -> T {
        return try decryptor(self.encryptedValue)
    }
}

extension Locked where T == String {
    public init(clearValue: T, with key: Keymaker.Key) throws {
        self.encryptedValue = try Locked<[String]>.init(clearValue: [clearValue], with: key).encryptedValue
    }
    
    public func unlock(with key: Keymaker.Key) throws -> T {
        guard let value = try Locked<[String]>.init(encryptedValue: self.encryptedValue).unlock(with: key).first else {
            throw Errors.failedToDecrypt
        }
        return value
    }
}

extension Locked where T == Data {
    public init(clearValue: T, with key: Keymaker.Key) throws {
        self.encryptedValue = try Locked<[Data]>.init(clearValue: [clearValue], with: key).encryptedValue
    }
    
    public func unlock(with key: Keymaker.Key) throws -> T {
        guard let value = try Locked<[Data]>.init(encryptedValue: self.encryptedValue).unlock(with: key).first else {
            throw Errors.failedToDecrypt
        }
        return value
    }
}

extension Locked where T: Codable {
    public init(clearValue: T, with key: Keymaker.Key) throws {
        let data = try PropertyListEncoder().encode(clearValue)
        var error: NSError?
        let cypherData = CryptoEncryptWithoutIntegrity(Data(bytes: key), data, Data(bytes: key.prefix(16)), &error)
        
        if let error = error {
            throw error
        }
        guard let lockedData = cypherData else {
            throw Errors.failedToEncrypt
        }
        
        self.encryptedValue = lockedData
    }
    
    public func unlock(with key: Keymaker.Key) throws -> T {
        var error: NSError?
        let clearData = CryptoDecryptWithoutIntegrity(Data(bytes: key), self.encryptedValue, Data(bytes: key.prefix(16)), &error)
            
        if let error = error {
            throw error
        }
        guard let unlockedData = clearData else {
            throw Errors.failedToDecrypt
        }
        
        let value = try PropertyListDecoder().decode(T.self, from: unlockedData)
        return value
    }
}
