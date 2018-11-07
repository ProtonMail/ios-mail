//
//  UserDefaultsSaver.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 07/11/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class UserDefaultsSaver<T>: Saver<T> where T: Codable {
    private let key: String
    init(key: String) {
        self.key = key
    }
    
    override func get() -> T? {
        guard let raw = SharedCacheBase.getDefault()?.data(forKey: self.key),
            let kit = try? PropertyListDecoder().decode(T.self, from: raw) else
        {
            return nil
        }
        return kit
    }
    
    override func set(newValue: T?) {
        guard let kit = newValue,
            let raw = try? PropertyListEncoder().encode(kit) else
        {
            SharedCacheBase.getDefault()?.removeObject(forKey: self.key)
            return
        }
        SharedCacheBase.getDefault()?.setValue(raw, forKey: self.key)
    }
}
