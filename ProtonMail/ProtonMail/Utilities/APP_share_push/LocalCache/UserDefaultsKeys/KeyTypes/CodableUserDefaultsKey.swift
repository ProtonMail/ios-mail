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

final class CodableUserDefaultsKey<T: Codable>: UserDefaultsKeys, OptionalUserDefaultsKey {
    private let dataKey: PlainUserDefaultsKey<Data>
    private let decoder = PropertyListDecoder()
    private let encoder = PropertyListEncoder()

    init(name: String) {
        dataKey = PlainUserDefaultsKey(name: name)
    }

    func readValue(from userDefaults: UserDefaults) -> T? {
        guard let data = dataKey.readValue(from: userDefaults) else {
            return nil
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            dataKey.writeValue(nil, to: userDefaults)

            PMAssertionFailure(error)

            return nil
        }
    }

    func writeValue(_ value: T?, to userDefaults: UserDefaults) {
        if let value {
            do {
                let data = try encoder.encode(value)
                dataKey.writeValue(data, to: userDefaults)
            } catch {
                PMAssertionFailure(error)
            }
        } else {
            dataKey.writeValue(nil, to: userDefaults)
        }
    }
}
