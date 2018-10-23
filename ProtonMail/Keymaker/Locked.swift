//
//  Locked.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 15/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import CryptoSwift

public struct Locked<T> {
    enum Errors: Error {
        case failedToTurnValueIntoData
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
        let aes = try AES(key: key, blockMode: ECB())
        let cypherBytes = try aes.encrypt(data.bytes)
        self.encryptedValue = Data(bytes: cypherBytes)
    }
    
    public func unlock(with key: Keymaker.Key) throws -> T {
        let aes = try AES(key: key, blockMode: ECB())
        let clearBytes = try aes.decrypt(self.encryptedValue.bytes)
        let data = Data(bytes: clearBytes)
        guard let value = String.init(data: data, encoding: .utf8) else {
            throw Errors.failedToTurnValueIntoData
        }
        return value
    }
}

extension Locked where T: Codable {
    public init(clearValue: T, with key: Keymaker.Key) throws {
        let data = try PropertyListEncoder().encode(clearValue)
        let aes = try AES(key: key, blockMode: ECB())
        let cypherBytes = try aes.encrypt(data.bytes)
        self.encryptedValue = Data(bytes: cypherBytes)
    }
    
    public func unlock(with key: Keymaker.Key) throws -> T {
        let aes = try AES(key: key, blockMode: ECB())
        let clearBytes = try aes.decrypt(self.encryptedValue.bytes)
        let data = Data(bytes: clearBytes)
        let value = try PropertyListDecoder().decode(T.self, from: data)
        return value
    }
}
