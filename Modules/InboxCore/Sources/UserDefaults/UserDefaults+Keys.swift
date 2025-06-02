//
// Copyright (c) 2025 Proton Technologies AG
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

extension UserDefaultsKey<String> {
    public static let primaryAccountSessionId = Self(name: "primaryAccountSessionId")
}

public struct UserDefaultsKey<T>: Sendable {
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

extension UserDefaults {
    public subscript<T>(key: UserDefaultsKey<T>) -> T? {
        get {
            object(forKey: key.name) as? T
        }
        set {
            set(newValue, forKey: key.name)
        }
    }

    public subscript<T>(key: UserDefaultsKey<[T]>) -> [T] {
        get {
            array(forKey: key.name) as? [T] ?? []
        }
        set {
            set(newValue, forKey: key.name)
        }
    }

    public subscript(key: UserDefaultsKey<Bool>) -> Bool {
        get {
            bool(forKey: key.name)
        }
        set {
            set(newValue, forKey: key.name)
        }
    }
}
