// Copyright (c) 2022 Proton Technologies AG
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

extension URL {
    var fileSize: Int {
        value(forKey: .fileSizeKey, keyPath: \.fileSize) ?? 0
    }

    func value<T>(forKey key: URLResourceKey, keyPath: KeyPath<URLResourceValues, T?>) -> T? {
        let values: URLResourceValues

        do {
            values = try resourceValues(forKeys: [key])
        } catch {
            assertionFailure("\(error)")
            return nil
        }

        guard let value = values[keyPath: keyPath] else {
            assertionFailure("Missing value for \(keyPath), perhaps you need a different key than \(key.rawValue)")
            return nil
        }

        return value
    }
}
