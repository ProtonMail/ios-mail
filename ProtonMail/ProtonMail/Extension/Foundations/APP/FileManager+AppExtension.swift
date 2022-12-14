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

extension FileManager {
    func sizeOfDirectory(url: URL) -> Int {
        guard let directoryEnumerator = enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            assertionFailure("What causes enumerator to be nil?")
            return 0
        }

        return directoryEnumerator.reduce(into: 0) { totalSize, element in
            guard let url = element as? URL else {
                assertionFailure("\(element) is not a URL")
                return
            }

            guard !url.hasDirectoryPath else {
                return
            }

            totalSize += url.fileSize
        }
    }
}
