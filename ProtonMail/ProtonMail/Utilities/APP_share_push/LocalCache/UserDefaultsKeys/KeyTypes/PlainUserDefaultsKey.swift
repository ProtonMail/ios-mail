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

final class PlainUserDefaultsKey<T: UserDefaultsStorable>: UserDefaultsKeys, OptionalUserDefaultsKey {
    let name: String

    init(name: String) {
        self.name = name
    }

    func readValue(from userDefaults: UserDefaults) -> T? {
        guard let storedValue = userDefaults.object(forKey: name) else {
            return nil
        }

        return storedValue as? T ?? {
            userDefaults.removeObject(forKey: name)

            PMAssertionFailure(
                "Cannot read \(name) - invalid type \(type(of: storedValue)), expected \(T.self)"
            )

            return nil
        }()
    }

    func writeValue(_ value: T?, to userDefaults: UserDefaults) {
        if let value {
            userDefaults.set(value, forKey: name)
        } else {
            userDefaults.removeObject(forKey: name)
        }
    }
}
