//
//  Saver.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 07/11/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

protocol KeyValueStoreProvider: class {
    func data(forKey key: String) -> Data?
    func removeItem(forKey key: String)
    func setData(_ data: Data, forKey key: String)
}

class Saver<T: Codable> {
    private let key: String
    private let store: KeyValueStoreProvider
    private lazy var value: T? = self.getFromStore()
    private var isCaching: Bool
    
    init(key: String, store: KeyValueStoreProvider, cachingInMemory: Bool = true) {
        self.key = key
        self.store = store
        self.isCaching = cachingInMemory
    }
    
    func get() -> T? {
        return self.isCaching ? self.value : self.getFromStore()
    }
}

extension Saver where T: Codable {
    private func getFromStore() -> T? {
        guard let raw = self.store.data(forKey: key),
            let subscription = try? PropertyListDecoder().decode(T.self, from: raw) else
        {
            return nil
        }
        return subscription
    }
    
    func set(newValue: T?) {
        self.value = newValue
        
        guard let value = newValue,
            let raw = try? PropertyListEncoder().encode(value) else
        {
            self.store.removeItem(forKey: key)
            return
        }
        self.store.setData(raw, forKey: key)
    }
}

extension Saver where T == String {
    private func getFromStore() -> T? {
        guard let raw = self.store.data(forKey: key),
            let subscription = String(bytes: raw, encoding: .utf8) else
        {
            return nil
        }
        return subscription
    }
    
    func set(newValue: T?) {
        self.value = newValue
        
        guard let value = newValue,
            let raw = value.data(using: .utf8) else
        {
            self.store.removeItem(forKey: key)
            return
        }
        self.store.setData(raw, forKey: key)
    }
}
