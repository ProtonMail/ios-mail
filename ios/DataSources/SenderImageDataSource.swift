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
import struct proton_mail_uniffi.MessageAddress
import enum SwiftUI.ColorScheme
import class SwiftUI.UIImage

protocol SenderImageDataSource {
    @MainActor
    func senderImage(for emails: [MessageAddress], colorScheme: ColorScheme) async -> UIImage?
}

final class SenderImageAPIDataSource: Sendable, SenderImageDataSource {
    static let shared: SenderImageAPIDataSource = .init()
    private let dependencies: Dependencies

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }

    func senderImage(for addresses: [MessageAddress], colorScheme: ColorScheme) async -> UIImage? {
        guard !addresses.isEmpty, let firstAddress = addresses.first else { return nil }
        if let cachedImage = await dependencies.cache.image(for: firstAddress.hashValue) {
            return cachedImage
        }
        do {
            guard let userSession = try await dependencies.appContext.userContextForActiveSession() else {
                return nil
            }
            guard let data = try await userSession
                .imageForSenders(
                    senders: addresses,
                    size: 128,
                    mode: colorScheme == .dark ? "dark" : "light",
                    format: "png"
                )
            else {
                return nil
            }
            let image = UIImage(data: data)
            if let firstAddress = addresses.first, let image {
                await dependencies.cache.setImage(image, for: firstAddress.hashValue)
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
        let cache: SenderImageMemoryCache = .shared
    }
}
