//
//  Locked.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 15/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import CryptoSwift

struct Locked<T> {
    private(set) var encryptedValue: Data
    
    init(encryptedValue: Data) {
        self.encryptedValue = encryptedValue
    }
    
    init(clearValue: T, with encryptor: (T)->Data) {
        self.encryptedValue = encryptor(clearValue)
    }
    
    func unlock(with decryptor: (Data)->Void) {
        return decryptor(self.encryptedValue)
    }
}

extension Locked where T: Codable {
    enum Errors: Error {
    case noKeyAvailable
    case failedToTurnValueIntoData
    }
    
    init(clearValue: T, with key: Keymaker.Key?) throws {
        guard let key = key else {
            throw Errors.noKeyAvailable
        }
        let data = try PropertyListEncoder().encode(clearValue)
        let aes = try AES(key: key, blockMode: CBC(iv: []))
        let cypherBytes = try aes.encrypt(data.bytes)
        self.encryptedValue = Data(bytes: cypherBytes)
    }
    
    func unlock(with key: Keymaker.Key?) throws -> T {
        guard let key = key else {
            throw Errors.noKeyAvailable
        }
        let aes = try AES(key: key, blockMode: CBC(iv: []))
        let clearBytes = try aes.decrypt(self.encryptedValue.bytes)
        let data = Data(bytes: clearBytes)
        let value = try PropertyListDecoder().decode(T.self, from: data)
        return value
    }
}
