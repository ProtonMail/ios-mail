// Copyright (c) 2024 Proton Technologies AG
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

extension UserDefaults {
    static func testInstance(inFile fileName: StaticString = #file) -> UserDefaults {
        .init(suiteName: suiteName(inFile: fileName)).unsafelyUnwrapped
    }

    static func clearedTestInstance(inFile fileName: StaticString = #file) -> UserDefaults {
        let defaults = testInstance(inFile: fileName)
        defaults.removePersistentDomain(forName: suiteName(inFile: fileName))
        return defaults
    }
}

private func suiteName(inFile fileName: StaticString = #file) -> String {
    let className = "\(fileName)".split(separator: ".")[0]
    return "com.proton.mail.test.\(className)"
}
