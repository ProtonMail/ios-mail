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

final class RawRepresentableUserDefaultsKey<T: RawRepresentable>:
    UserDefaultsKeys, OptionalUserDefaultsKey where T.RawValue: UserDefaultsStorable {
    private let rawValueKey: PlainUserDefaultsKey<T.RawValue>

    init(name: String) {
        rawValueKey = PlainUserDefaultsKey(name: name)
    }

    func readValue(from userDefaults: UserDefaults) -> T? {
        guard let rawValue = rawValueKey.readValue(from: userDefaults) else {
            return nil
        }

        return T(rawValue: rawValue) ?? {
            rawValueKey.writeValue(nil, to: userDefaults)

            PMAssertionFailure(
                "Cannot read \(rawValueKey.name) - invalid type \(type(of: rawValue)), expected \(T.self)"
            )

            return nil
        }()
    }

    func writeValue(_ value: T?, to userDefaults: UserDefaults) {
        rawValueKey.writeValue(value?.rawValue, to: userDefaults)
    }
}
