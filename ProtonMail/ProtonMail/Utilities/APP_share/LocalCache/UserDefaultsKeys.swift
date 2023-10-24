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
    static let lastBugReport = UserDefaultsKey<String>(name: "BugReportCache_LastBugReport", defaultValue: "")
}

final class UserDefaultsKey<T>: UserDefaultsKeys {
    let name: String
    let defaultValue: T

    init(name: String, defaultValue: T) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

extension UserDefaults {
    subscript<T>(_ key: UserDefaultsKey<T>) -> T {
        get {
            guard let storedValue = object(forKey: key.name) else {
                return key.defaultValue
            }

            return storedValue as? T ?? {
                PMAssertionFailure(
                    "Cannot read \(key.name) - invalid type \(type(of: storedValue)), expected \(T.self)"
                )
                return key.defaultValue
            }()
        }
        set {
            set(newValue, forKey: key.name)
        }
    }
}
