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
import UIKit
import UniformTypeIdentifiers

enum TestDataFactory {
    static func makeItemProviders(types: [UTType], count: UInt) -> [NSItemProvider] {
        (0..<count).map { index in
            let itemProvider = NSItemProvider()

            for type in types {
                let url = URL(fileURLWithPath: "attachments/\(index)-\(type.identifier)")

                itemProvider.registerFileRepresentation(for: type) { completion in
                    completion(url, true, nil)
                    return nil
                }
            }

            return itemProvider
        }
    }

    static func stubImages(in urls: [URL]) throws -> [NSItemProvider] {
        let image = UIImage(systemName: "checkmark")!

        return try urls.map { url in
            try image.pngData()!.write(to: url)

            let itemProvider = NSItemProvider()

            itemProvider.registerFileRepresentation(for: .png) { completion in
                completion(url, true, nil)
                return nil
            }

            return itemProvider
        }
    }

    static func stubShortLivedData(in urls: [URL]) throws -> [NSItemProvider] {
        let data = Data("foo".utf8)

        return try urls.map { url in
            try data.write(to: url, options: [.withoutOverwriting, .noFileProtection])

            let itemProvider = NSItemProvider()

            itemProvider.registerFileRepresentation(for: .data) { completion in
                completion(url, true, nil)
                try! FileManager.default.removeItem(at: url)
                return nil
            }

            return itemProvider
        }
    }
}
