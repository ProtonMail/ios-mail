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

import proton_app_uniffi

typealias EmbeddedImageClosure = (_ mailbox: Mailbox, _ id: ID, _ cid: String) async -> GetEmbeddedAttachmentResult

struct EmbeddedImageRepository {
    private let mailbox: Mailbox
    private let embeddedImageProvider: EmbeddedImageClosure

    init(mailbox: Mailbox, embeddedImageProvider: @escaping EmbeddedImageClosure) {
        self.mailbox = mailbox
        self.embeddedImageProvider = embeddedImageProvider
    }

    func embeddedImage(messageID: ID, cid: String) async throws -> EmbeddedImage {
        switch await embeddedImageProvider(mailbox, messageID, cid) {
        case .ok(let imageMetadata):
            imageMetadata.embeddedImage
        case .error(let error):
            throw error
        }
    }
}

private extension EmbeddedAttachmentInfo {

    var embeddedImage: EmbeddedImage {
        .init(data: data, mimeType: mime)
    }

}
