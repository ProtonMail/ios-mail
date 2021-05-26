//
//  KeychainSaver.swift
//  ProtonMail - Created on 07/11/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

class KeychainSaver<T>: Saver<T> where T: Codable {
    convenience init(key: String, cachingInMemory: Bool = true) {
        self.init(key: key, store: KeychainWrapper.keychain, cachingInMemory: cachingInMemory)
    }
}

extension KeychainWrapper: KeyValueStoreProvider {

    func bool(forKey defaultName: String) -> Bool {
        assert(false, "Looks like this one is never actually used")
        return false
    }

    func set(_ value: Bool, forKey defaultName: String) {
        assert(false, "Looks like this one is never actually used")
    }

    public func set(_ intValue: Int, forKey key: String) {
        assert(false, "Looks like this one is never actually used")
    }
    
    public func int(forKey key: String) -> Int? {
        assert(false, "Looks like this one is never actually used")
        return nil
    }
    
}
