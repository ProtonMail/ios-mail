//
//  KeychainSaver.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 07/11/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class KeychainSaver<T>: Saver<T> where T: Codable {
    private let key: String
    init(key: String) {
        self.key = key
    }
    
    override func get() -> T? {
        guard let raw = sharedKeychain.keychain.data(forKey: key),
            let subscription = try? PropertyListDecoder().decode(T.self, from: raw) else
        {
            return nil
        }
        return subscription
    }
    
    override func set(newValue: T?) {
        guard let value = newValue,
            let raw = try? PropertyListEncoder().encode(value) else
        {
            sharedKeychain.keychain.removeItem(forKey: key)
            return
        }
        sharedKeychain.keychain.setData(raw, forKey: key)
    }
}
