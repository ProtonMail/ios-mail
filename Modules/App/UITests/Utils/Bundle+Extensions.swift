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

extension Bundle {
    /// Gets the JSON data from the `Bundle` and returns is as `Data?`.
    /// - Parameter fileName: The filename with the extension.
    /// - Returns: A `Data?` containing the file content. Value is `nil` in case an error occurs.
    @Sendable func getDataFor(fileName: String) -> Data? {
        let file = fileName.components(separatedBy: ".")

        if let filepath = self.path(forResource: file.first, ofType: file.last) {
            do {
                let url = URL(fileURLWithPath: filepath)
                return try Data(contentsOf: url)
            } catch {
                print("An error occurred while parsing file \(fileName).")
                return nil
            }
        } else {
            print("Could not find file \(fileName), unable to retrieve file contents.")
            return nil
        }
    }
}
