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
import struct proton_mail_uniffi.MessageAddress

struct AsyncSenderImageView<Content>: View where Content: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @StateObject private var loader: SenderImageLoader
    @ViewBuilder private var content: (SenderImageLoader.Image) -> Content

    private let senderImageParams: SenderImageDataParameters

    init(
        loader: SenderImageLoader = .init(),
        senderImageParams: SenderImageDataParameters,
        @ViewBuilder content: @escaping (SenderImageLoader.Image) -> Content
    ) {
        _loader = .init(wrappedValue: loader)
        self.senderImageParams = senderImageParams
        self.content = content
    }

    var body: some View {
        content(loader.senderImage)
            .onAppear() {
                Task {
                    await loader.loadImage(for: senderImageParams, colorScheme: colorScheme)
                }
            }
    }
}

final class SenderImageLoader: ObservableObject {
    enum Image {
        case empty
        case image(_ image: UIImage)
    }

    @Published var senderImage: Image = .empty
    private let provider: SenderImageDataSource

    init(provider: SenderImageDataSource = SenderImageAPIDataSource.shared) {
        self.provider = provider
    }

    @MainActor
    func loadImage(for params: SenderImageDataParameters, colorScheme: ColorScheme) async {
        guard let image = await provider.senderImage(for: params, colorScheme: colorScheme) else {
            senderImage = .empty
            return
        }
        senderImage = .image(image)
    }
}

#Preview {
    class DummyDataSource: SenderImageDataSource {
        func senderImage(for params: SenderImageDataParameters, colorScheme: ColorScheme) async -> UIImage? {
            UIImage(resource: PreviewData.senderImage)
        }        
    }
    let loader = SenderImageLoader(provider: DummyDataSource())

    return AsyncSenderImageView(loader: loader, senderImageParams: .init()) { image in
        switch image {
        case .empty:
            Text("EMPTY".notLocalized)
        case .image(let img):
            Image(uiImage: img)
        }
    }
}
