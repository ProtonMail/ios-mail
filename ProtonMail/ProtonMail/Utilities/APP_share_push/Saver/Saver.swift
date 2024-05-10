//
//  Saver.swift
//  Proton Mail - Created on 07/11/2018.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

protocol KeyValueStoreProvider: AnyObject {
    func data(forKey key: String, attributes: [CFString: Any]?) -> Data?
    func set(_ data: Data, forKey key: String, attributes: [CFString: Any]?)
    func remove(forKey key: String)
}

class Saver<T: Codable> {
    private let key: String
    private let store: KeyValueStoreProvider
    private var value: T?
    private var isCaching: Bool

    init(key: String, store: KeyValueStoreProvider, cachingInMemory: Bool = true) {
        self.key = key
        self.store = store
        self.isCaching = cachingInMemory
    }
}

extension Saver where T == String {
    func set(newValue: String?) {
        if isCaching {
            self.value = newValue
        }
        guard let value = newValue,
            let raw = value.data(using: .utf8) else {
            self.store.remove(forKey: key)
            return
        }
        self.store.set(raw, forKey: key, attributes: nil)
    }
}

extension Saver where T: Codable {
    private func getFromStore() -> T? {
        guard let raw = self.store.data(forKey: key, attributes: nil),
            let subscription = try? PropertyListDecoder().decode(T.self, from: raw) else {
            return nil
        }
        return subscription
    }

    func set(newValue: T?) {
        self.value = newValue

        guard let value = newValue,
            let raw = try? PropertyListEncoder().encode(value) else {
            self.store.remove(forKey: key)
            return
        }
        self.store.set(raw, forKey: key, attributes: nil)
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
