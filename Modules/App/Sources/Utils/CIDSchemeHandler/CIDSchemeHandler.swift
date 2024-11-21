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
import WebKit

class CIDSchemeHandler: NSObject, WKURLSchemeHandler {
    private let embeddedImageRepository: EmbeddedImageRepository
    private let messageID: ID

    init(
        mailbox: Mailbox,
        messageID: ID,
        embeddedImageProvider: @escaping EmbeddedImageClosure = getEmbeddedAttachment
    ) {
        self.embeddedImageRepository = .init(mailbox: mailbox, embeddedImageProvider: embeddedImageProvider)
        self.messageID = messageID
    }

    enum HandlerError: Error, Equatable {
        case missingCID
        case imageNotAvailable
    }

    static let handlerScheme = "cid"

    // MARK: - WKURLSchemeHandler

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let url = urlSchemeTask.request.url
        guard let url, url.scheme == Self.handlerScheme else {
            urlSchemeTask.didFailWithError(HandlerError.missingCID)
            return
        }

        let cid = url.absoluteString
            .replacingOccurrences(of: "\(Self.handlerScheme):", with: "")

        image(url: url, cid: cid, urlSchemeTask: urlSchemeTask)
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    // MARK: - Private

    private func image(url: URL, cid: String, urlSchemeTask: WKURLSchemeTask) {
        Task {
            let image = try? await embeddedImageRepository.embeddedImage(messageID: messageID, cid: cid)
            if let image {
                let response = URLResponse(
                    url: url,
                    mimeType: image.mimeType,
                    expectedContentLength: image.data.count,
                    textEncodingName: nil
                )
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(image.data)
                urlSchemeTask.didFinish()
            } else {
                urlSchemeTask.didFailWithError(HandlerError.imageNotAvailable)
            }
        }
    }
}
