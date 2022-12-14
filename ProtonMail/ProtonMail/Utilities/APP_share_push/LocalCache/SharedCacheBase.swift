//
//  SharedCacheBase.swift
//  Proton Mail - Created on 6/5/15.
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

class SharedCacheBase {
    private let userDefaults: UserDefaults

    init () {
        self.userDefaults = UserDefaults(suiteName: Constants.AppGroup)!
    }

    func getShared() -> UserDefaults {
        return self.userDefaults
    }

    func setValue(_ value: Any?, forKey key: String) {
        self.userDefaults.setValue(value, forKey: key)
        self.userDefaults.synchronize()
    }

    class func getDefault() -> UserDefaults! {
        return UserDefaults(suiteName: Constants.AppGroup)
    }
}

extension UserDefaults {
    func decodableValue<T: Decodable>(forKey key: String) -> T? {
        guard let data = data(forKey: key) else {
            return nil
        }

        do {
            return try PropertyListDecoder().decode(T.self, from: data)
        } catch {
            assertionFailure("\(error)")
            return nil
        }
    }

    func setEncodableValue<T: Encodable>(_ value: T?, forKey key: String) {
        if let newValue = value {
            do {
                let data = try PropertyListEncoder().encode(newValue)
                setValue(data, forKey: key)
            } catch {
                assertionFailure("\(error)")
            }
        } else {
            removeObject(forKey: key)
        }
    }
}
