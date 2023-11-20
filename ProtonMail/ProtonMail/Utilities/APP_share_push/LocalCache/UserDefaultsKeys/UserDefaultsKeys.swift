// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

class UserDefaultsKeys {
    static func plainKey<T: UserDefaultsStorable>(
        named name: String,
        ofType type: T.Type
    ) -> PlainUserDefaultsKey<T> {
        PlainUserDefaultsKey(name: name)
    }

    static func plainKey<T: UserDefaultsStorable>(
        named name: String,
        defaultValue: T
    ) -> NonOptionalKey<PlainUserDefaultsKey<T>> {
        NonOptionalKey(name: name, defaultValue: defaultValue)
    }

    static func rawRepresentableKey<T: RawRepresentable>(
        named name: String,
        defaultValue: T
    ) -> NonOptionalKey<RawRepresentableUserDefaultsKey<T>> {
        NonOptionalKey(name: name, defaultValue: defaultValue)
    }

    static func codableKey<T: Codable>(
        named name: String,
        ofType type: T.Type
    ) -> CodableUserDefaultsKey<T> {
        CodableUserDefaultsKey(name: name)
    }
}

extension UserDefaults {
    subscript<T>(_ key: PlainUserDefaultsKey<T>) -> T? {
        get {
            key.readValue(from: self)
        }
        set {
            key.writeValue(newValue, to: self)
        }
    }

    subscript<T>(_ key: RawRepresentableUserDefaultsKey<T>) -> T? {
        get {
            key.readValue(from: self)
        }
        set {
            key.writeValue(newValue, to: self)
        }
    }

    subscript<T>(_ key: CodableUserDefaultsKey<T>) -> T? {
        get {
            key.readValue(from: self)
        }
        set {
            key.writeValue(newValue, to: self)
        }
    }

    subscript<T>(_ key: NonOptionalKey<T>) -> T.ValueType {
        get {
            key.wrappedOptionalKey.readValue(from: self) ?? key.defaultValue
        }
        set {
            key.wrappedOptionalKey.writeValue(newValue, to: self)
        }
    }
}
