//
//  KeychainSaver.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 07/11/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class KeychainSaver<T>: Saver<T> where T: Codable {
    convenience init(key: String, cachingInMemory: Bool = true) {
        self.init(key: key, store: sharedKeychain, cachingInMemory: cachingInMemory)
    }
}

extension KeychainWrapper: KeyValueStoreProvider {
    func data(forKey key: String) -> Data? {
        return self.keychain.data(forKey: key)
    }
    
    func removeItem(forKey key: String) {
        self.keychain.removeItem(forKey: key)
    }
    
    func setData(_ data: Data, forKey key: String) {
        self.keychain.setData(data, forKey: key)
    }
}
