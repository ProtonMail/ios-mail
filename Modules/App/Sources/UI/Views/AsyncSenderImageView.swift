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

import SwiftUI

struct AsyncSenderImageView<Content>: View where Content: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @StateObject private var loader: SenderImageLoader
    @ViewBuilder private var content: (SenderImageLoader.Image) -> Content

    private let senderImageParams: SenderImageDataParameters

    init(
        senderImageParams: SenderImageDataParameters,
        @ViewBuilder content: @escaping (SenderImageLoader.Image) -> Content
    ) {
        _loader = StateObject(wrappedValue: .init(address: senderImageParams.address))
        self.senderImageParams = senderImageParams
        self.content = content
    }

    var body: some View {
        content(loader.senderImage)
            .onAppear {
                Task {
                    await loader.loadImage(for: senderImageParams, colorScheme: colorScheme)
                }
            }
    }
}

@MainActor
final class SenderImageLoader: ObservableObject {
    enum Image {
        case empty
        case image(_ image: UIImage)
    }

    @Published var senderImage: Image
    private let dependencies: Dependencies

    init(address: String, dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
        if let image = self.dependencies.cache.object(for: address) {
            senderImage = .image(image)
        } else {
            senderImage = .empty
        }
    }

    func loadImage(for params: SenderImageDataParameters, colorScheme: ColorScheme) async {
        guard let image = await dependencies.imageDataSource.senderImage(for: params, colorScheme: colorScheme) else {
            senderImage = .empty
            return
        }
        senderImage = .image(image)
    }
}

extension SenderImageLoader {
    struct Dependencies {
        let imageDataSource: SenderImageDataSource
        let cache: MemoryCache<String, UIImage>

        init(
            imageDataSource: SenderImageDataSource = SenderImageAPIDataSource.shared,
            cache: MemoryCache<String, UIImage> = Caches.senderImageCache
        ) {
            self.imageDataSource = imageDataSource
            self.cache = cache
        }
    }
}

#Preview {
    class DummyDataSource: SenderImageDataSource {
        func senderImage(for params: SenderImageDataParameters, colorScheme: ColorScheme) async -> UIImage? {
            UIImage(resource: PreviewData.senderImage)
        }
    }

    return AsyncSenderImageView(senderImageParams: .init()) { image in
        switch image {
        case .empty:
            Text("EMPTY".notLocalized)
        case .image(let img):
            Image(uiImage: img)
        }
    }
}
