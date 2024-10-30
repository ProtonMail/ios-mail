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
import enum SwiftUI.ColorScheme
import class SwiftUI.UIImage
import func proton_app_uniffi.mailSettings

protocol SenderImageDataSource {
    @MainActor
    func senderImage(for params: SenderImageDataParameters, colorScheme: ColorScheme) async -> UIImage?
}

/// This is the information required by the Rust SDK to retrieve a sender's avatar image
struct SenderImageDataParameters {
    let address: String
    let bimiSelector: String?
    let displaySenderImage: Bool

    init(address: String = "", bimiSelector: String? = nil, displaySenderImage: Bool = true) {
        self.address = address
        self.bimiSelector = bimiSelector
        self.displaySenderImage = displaySenderImage
    }
}

final class SenderImageAPIDataSource: Sendable, SenderImageDataSource {
    static let shared: SenderImageAPIDataSource = .init()
    private let dependencies: Dependencies

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }

    func senderImage(for params: SenderImageDataParameters, colorScheme: ColorScheme) async -> UIImage? {
        if let cachedImage = dependencies.cache.object(for: params.address) {
            return cachedImage
        }
        do {
            guard case .activeSession(let userSession) = dependencies.appContext.sessionState else {
                return nil
            }
            guard let imageFilePath = try await userSession
                .imageForSender(
                    address: params.address,
                    bimiSelector: params.bimiSelector,
                    displaySenderImage: params.displaySenderImage,
                    size: 128,
                    mode: colorScheme == .dark ? "dark" : "light",
                    format: "png"
                )
            else {
                return nil
            }
            let image = UIImage(contentsOfFile: imageFilePath)
            if let image {
                dependencies.cache.setObject(image, for: params.address)
            }
            return image
        } catch {
            AppLogger.log(error: error)
            return nil
        }
    }
}

extension SenderImageAPIDataSource {

    struct Dependencies {
        let appContext: AppContext = .shared
        let cache: MemoryCache<String, UIImage> = Caches.senderImageCache
    }
}
