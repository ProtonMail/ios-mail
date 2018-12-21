//
//  Locked.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 15/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

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
