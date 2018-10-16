//
//  Locked.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 15/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

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
    init(clearValue: T, with key: SecKey?) throws {
        let data = try! PropertyListEncoder().encode(clearValue)
        // FIXME: actually encrypt the value
        self.encryptedValue = data.base64EncodedData()
    }
    
    func unlock(with key: SecKey?) throws -> T {
        // FIXME: actually decrypt the value
        let decryptedValue = Data(base64Encoded: self.encryptedValue)!
        let value = try! PropertyListDecoder().decode(T.self, from: decryptedValue)
        return value
    }
}
