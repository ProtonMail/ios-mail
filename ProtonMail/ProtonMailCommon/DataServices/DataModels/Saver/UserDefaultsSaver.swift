//
//  UserDefaultsSaver.swift
//  ProtonMail - Created on 07/11/2018.
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

class UserDefaultsSaver<T>: Saver<T> where T: Codable {
    convenience init(key: String) {
        self.init(key: key, store: SharedCacheBase.getDefault())
    }
}

extension UserDefaults: KeyValueStoreProvider {
    func int(forKey key: String) -> Int? {
        return self.object(forKey: key) as? Int
    }

    func data(forKey key: String) -> Data? {
        return self.object(forKey: key) as? Data
    }

    func set(_ data: Int, forKey key: String) {
        self.setValue(data, forKey: key)
    }

    func set(_ data: Data, forKey key: String) {
        self.setValue(data, forKey: key)
    }

    func remove(forKey key: String) {
        self.removeObject(forKey: key)
    }

}
