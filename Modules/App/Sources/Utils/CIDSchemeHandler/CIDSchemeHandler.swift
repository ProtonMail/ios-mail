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

    init(embeddedImageProvider: EmbeddedImageProvider) {
        self.embeddedImageRepository = .init(embeddedImageProvider: embeddedImageProvider)
    }

    enum HandlerError: Error, Equatable {
        case missingCID
    }

    static let handlerScheme = "cid"

    // MARK: - WKURLSchemeHandler

    /// Handles custom `cid` schemes in the HTML body loaded into the `WKWebView`.
    ///
    /// This method is invoked by the `WKWebView` when a resource with a `cid` scheme is requested.
    /// The `cid` scheme is used to reference inline resources, such as images within
    /// HTML content, and connect them with correct message attachments.
    /// The function retrieves the requested resource from the Rust SDK and provides it to the web view as a response.
    ///
    /// Example HTML with cid scheme
    ///
    /// <div style="font-family: Arial, sans-serif; font-size: 14px;">
    ///    Here is embedded image -> <img alt="embedded_image.png" src="cid:43affe26@protonmail.com">
    /// </div>
    ///
    /// In above's case when html is loaded to the web view and this handler is registered as cid scheme handler for web view,
    /// it will call this function where the `urlSchemeTask` requested URL will be `cid:43affe26@protonmail.com`
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let url = urlSchemeTask.request.url
        guard let url, url.scheme == Self.handlerScheme else {
            urlSchemeTask.didFailWithError(HandlerError.missingCID)
            return
        }

        let cid = url.absoluteString
            .replacingOccurrences(of: "\(Self.handlerScheme):", with: "")

        finishTaskWithImage(url: url, cid: cid, urlSchemeTask: urlSchemeTask)
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    // MARK: - Private

    private func finishTaskWithImage(url: URL, cid: String, urlSchemeTask: WKURLSchemeTask) {
        Task {
            do {
                let image = try await embeddedImageRepository.embeddedImage(cid: cid)
                let response = URLResponse(
                    url: url,
                    mimeType: image.mimeType,
                    expectedContentLength: image.data.count,
                    textEncodingName: nil
                )
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(image.data)
                urlSchemeTask.didFinish()
            } catch {
                urlSchemeTask.didFailWithError(error)
            }
        }
    }
}
