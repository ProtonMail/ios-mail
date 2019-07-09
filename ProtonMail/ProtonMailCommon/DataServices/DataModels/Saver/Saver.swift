//
//  Saver.swift
//  ProtonMail - Created on 07/11/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation

protocol KeyValueStoreProvider: class {
    func data(forKey key: String) -> Data?
    func int(forKey key: String) -> Int?
    func set(_ intValue: Int, forKey key: String)
    func set(_ data: Data, forKey key: String)
    func remove(forKey key: String)
}

class Saver<T: Codable> {
    private let key: String
    private let store: KeyValueStoreProvider
    private var value: T? = nil
    private var isCaching: Bool
    
    init(key: String, store: KeyValueStoreProvider, cachingInMemory: Bool = true) {
        self.key = key
        self.store = store
        self.isCaching = cachingInMemory
    }
}

extension Saver where T == String {
    private func getString() -> String? {
        guard let raw = self.store.data(forKey: key),
            let subscription = String(bytes: raw, encoding: .utf8) else
        {
            return nil
        }
        return subscription
    }
    
    func set(newValue: String?) {
        if isCaching {
            self.value = newValue
        }
        guard let value = newValue,
            let raw = value.data(using: .utf8) else
        {
            self.store.remove(forKey: key)
            return
        }
        self.store.set(raw, forKey: key)
    }
    
    func get() -> String? {
        guard self.isCaching == true else {
            return self.getString()
        }
        guard self.value == nil else {
            return self.value
        }
        self.value = self.getString()
        return self.value
    }
}

extension Saver where T == Int {
    private func getInt() -> Int? {
        guard let raw = self.store.int(forKey: key) else {
            return nil
        }
        return raw
    }
    
    func set(newValue: Int?) {
        if isCaching {
            self.value = newValue
        }
        guard let value = newValue else {
            self.store.remove(forKey: key)
            return
        }
        self.store.set(value, forKey: key)
    }
    func get() -> Int? {
        guard self.isCaching == true else {
            return self.getInt()
        }
        guard self.value == nil else {
            return self.value
        }
        self.value = self.getInt()
        return self.value
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
            self.store.remove(forKey: key)
            return
        }
        self.store.set(raw, forKey: key)
    }
    
    func get() -> T? {
        guard self.isCaching == true else {
            return self.getFromStore()
        }
        guard self.value == nil else {
            return self.value
        }
        self.value = self.getFromStore()
        return self.value
    }
}
