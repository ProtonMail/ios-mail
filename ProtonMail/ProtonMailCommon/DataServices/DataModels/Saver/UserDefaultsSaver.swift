//
//  UserDefaultsSaver.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 07/11/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class UserDefaultsSaver<T>: Saver<T> where T: Codable {
    convenience init(key: String) {
        self.init(key: key, store: SharedCacheBase.getDefault())
    }
}

extension UserDefaults: KeyValueStoreProvider {
    func data(forKey key: String) -> Data? {
        return self.object(forKey: key) as? Data
    }
    
    func removeItem(forKey key: String) {
        self.removeObject(forKey: key)
    }
    
    func setData(_ data: Data, forKey key: String) {
        self.setValue(data, forKey: key)
    }
}
