//
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

import UIKit
import UniformTypeIdentifiers

extension NSItemProvider {
    var hasImageRepresentation: Bool {
        hasItemConformingToTypeIdentifier(UTType.image.identifier)
    }

    func loadString() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            _ = loadObject(ofClass: String.self) { value, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: value!)
                }
            }
        }
    }

    func performOnFileRepresentation<T>(block: @escaping (URL) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            _ = loadFileRepresentation(for: .data) { shortLivedURL, _, error in
                continuation.resume(
                    with: .init {
                        guard let shortLivedURL else {
                            throw error!
                        }

                        return try block(shortLivedURL)
                    }
                )
            }
        }
    }
}
