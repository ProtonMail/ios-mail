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

// swiftlint:disable:all discouraged_optional_boolean
class UserDefaultsKeys {
    static let primaryUserSessionId = UserDefaultsKey<String?>(name: "primary_user_session_id", defaultValue: nil)
    static let failedPushNotificationDecryption = UserDefaultsKey<Bool?>(
        name: "failedPushNotificationDecryption",
        defaultValue: nil
    )
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
            /*
             `set(nil, forKey:)` is not a valid operation if generics are used; it would throw this warning:

             [User Defaults] Attempt to set a non-property-list object <null> as an NSUserDefaults/CFPreferences value

             We need to use `remove(forKey:)` to set nil, but it's not simply a matter of adding an `if let` without
             making T always optional or adding a separate subscript.
             */
            if newValue as AnyObject is NSNull {
                removeObject(forKey: key.name)
            } else {
                set(newValue, forKey: key.name)
            }
        }
    }
}
