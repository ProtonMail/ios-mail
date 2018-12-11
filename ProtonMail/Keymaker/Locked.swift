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
        guard let data = clearValue.data(using: .utf8) else {
            throw Errors.failedToTurnValueIntoData
        }
        
        var error: NSError?
        let cypherBytes = CryptoEncryptWithoutIntegrity(key, data, key.subdata(in: .init(uncheckedBounds: (lower: 0, upper: 16))), &error) ?? Data()
        
        if let error = error {
            throw error
        }
        self.encryptedValue = cypherBytes
    }
    
    public func unlock(with key: Keymaker.Key) throws -> T {
        var error: NSError?
        let clearBytes = CryptoDecryptWithoutIntegrity(key, self.encryptedValue, key.subdata(in: .init(uncheckedBounds: (lower: 0, upper: 16))), &error) ?? Data()
        if let error = error {
            throw error
        }

        guard let value = String(data: clearBytes, encoding: .utf8) else {
            throw Errors.failedToTurnValueIntoData
        }
        return value
    }
}

extension Locked where T == Data {
    public init(clearValue: T, with key: Keymaker.Key) throws {
        var error: NSError?
        let cypherBytes = CryptoEncryptWithoutIntegrity(key, clearValue, key.subdata(in: .init(uncheckedBounds: (lower: 0, upper: 16))), &error) ?? Data()
        
        if let error = error {
            throw error
        }
        self.encryptedValue = cypherBytes
    }
    
    public func unlock(with key: Keymaker.Key) throws -> T {
        var error: NSError?
        let clearBytes = CryptoDecryptWithoutIntegrity(key, self.encryptedValue, key.subdata(in: .init(uncheckedBounds: (lower: 0, upper: 16))), &error) ?? Data()
            
        if let error = error {
            throw error
        }
        return clearBytes
    }
}

extension Locked where T: Codable {
    public init(clearValue: T, with key: Keymaker.Key) throws {
        let data = try PropertyListEncoder().encode(clearValue)
        var error: NSError?
        let cypherBytes = CryptoEncryptWithoutIntegrity(key, data, key.subdata(in: .init(uncheckedBounds: (lower: 0, upper: 16))), &error) ?? Data()
            
        if let error = error {
            throw error
        }
        self.encryptedValue = Data(bytes: cypherBytes)
    }
    
    public func unlock(with key: Keymaker.Key) throws -> T {
        var error: NSError?
        let clearBytes = CryptoDecryptWithoutIntegrity(key, self.encryptedValue, key.subdata(in: .init(uncheckedBounds: (lower: 0, upper: 16))), &error) ?? Data()
            
        if let error = error {
            throw error
        }
        let value = try PropertyListDecoder().decode(T.self, from: clearBytes)
        return value
    }
}
