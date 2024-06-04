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
    func dataOrError(forKey key: String, attributes: [CFString: Any]?) throws -> Data?
    func setOrError(_ data: Data, forKey key: String, attributes: [CFString: Any]?) throws
    func removeOrError(forKey key: String) throws
}

class Saver<T: Codable> {
    private let key: String
    private let store: KeyValueStoreProvider

    init(key: String, store: KeyValueStoreProvider) {
        self.key = key
        self.store = store
    }
}

extension Saver where T: Codable {
    func get() -> T? {
        do {
            guard let raw = try store.dataOrError(forKey: key, attributes: nil) else {
                return nil
            }

            return try PropertyListDecoder().decode(T.self, from: raw)
        } catch {
            SystemLogger.log(error: error)
            return nil
        }
    }

    func set(newValue: T?) {
        do {
            if let newValue {
                let raw = try PropertyListEncoder().encode(newValue)
                try store.setOrError(raw, forKey: key, attributes: nil)
            } else {
                try store.removeOrError(forKey: key)
            }
        } catch {
            SystemLogger.log(error: error)
        }
    }
}
