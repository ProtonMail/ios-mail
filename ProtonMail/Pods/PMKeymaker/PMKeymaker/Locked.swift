//
//  Locked.swift
//  ProtonMail - Created on 15/10/2018.
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

import Foundation

public enum Errors: Error {
    case failedToTurnValueIntoData
    case keyDoesNotMatch
    case failedToEncrypt
    case failedToDecrypt
}

fileprivate let IVsize : Int = 16
public struct GenericLocked<T, SUBTLE: SubtleProtocol> {
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

extension GenericLocked where T == String {
    public init(clearValue: T, with key: Key) throws {
        self.encryptedValue = try GenericLocked<[String], SUBTLE>.init(clearValue: [clearValue], with: key).encryptedValue
    }
    
    public func unlock(with key: Key) throws -> T {
        guard let value = try GenericLocked<[String], SUBTLE>.init(encryptedValue: self.encryptedValue).unlock(with: key).first else {
            throw Errors.failedToDecrypt
        }
        return value
    }
    
    public func lagcyUnlock(with key: Key) throws -> T {
        guard let value = try GenericLocked<[String], SUBTLE>.init(encryptedValue: self.encryptedValue).lagcyUnlock(with: key).first else {
            throw Errors.failedToDecrypt
        }
        return value
    }
}

extension GenericLocked where T == Data {
    public init(clearValue: T, with key: Key) throws {
        self.encryptedValue = try GenericLocked<[Data], SUBTLE>.init(clearValue: [clearValue], with: key).encryptedValue
    }
    
    public func unlock(with key: Key) throws -> T {
        guard let value = try GenericLocked<[Data], SUBTLE>.init(encryptedValue: self.encryptedValue).unlock(with: key).first else {
            throw Errors.failedToDecrypt
        }
        return value
    }
    
    public func lagcyUnlock(with key: Key) throws -> T {
        guard let value = try GenericLocked<[Data], SUBTLE>.init(encryptedValue: self.encryptedValue).lagcyUnlock(with: key).first else {
            throw Errors.failedToDecrypt
        }
        return value
    }
}

extension GenericLocked where T: Codable {
    public init(clearValue: T, with key: Key) throws {
        let data = try PropertyListEncoder().encode(clearValue)
        var error: NSError?
        
        var random = SUBTLE.Random(IVsize) ?? Data(key.prefix(IVsize))
        
        let cypherData = SUBTLE.EncryptWithoutIntegrity(Data(key), data, random, &error)
        
        if let error = error {
            throw error
        }
        guard let lockedData = cypherData else {
            throw Errors.failedToEncrypt
        }
        var enData = NSMutableData()
        enData.append(random)
        enData.append(lockedData)
        self.encryptedValue = enData as Data
    }
    
    public func unlock(with key: Key) throws -> T {
        var error: NSError?
        let randomIV = self.encryptedValue.prefix(IVsize)

        let mutableData = NSMutableData(data: self.encryptedValue)
        mutableData.replaceBytes(in: NSMakeRange(0,IVsize), withBytes: nil, length: 0)
        let valu1e = mutableData as Data
        let clearData = SUBTLE.DecryptWithoutIntegrity(Data(key), valu1e, randomIV, &error)

        if let error = error {
            throw error
        }
        guard let unlockedData = clearData else {
            throw Errors.failedToDecrypt
        }
        let value = try PropertyListDecoder().decode(T.self, from: unlockedData)
        return value
    }
    
    public func lagcyUnlock(with key: Key) throws -> T {
        var error: NSError?
        let clearData = SUBTLE.DecryptWithoutIntegrity(Data(key), self.encryptedValue, Data(key.prefix(IVsize)), &error)
        
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
