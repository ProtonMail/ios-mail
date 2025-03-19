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

public final class CIDSchemeHandler: NSObject, WKURLSchemeHandler {
    private let embeddedImageProvider: EmbeddedImageProvider

    public init(embeddedImageProvider: EmbeddedImageProvider) {
        self.embeddedImageProvider = embeddedImageProvider
    }

    public enum HandlerError: Error, Equatable {
        case missingCID
    }

    public static let handlerScheme = "cid"

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
    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let url = urlSchemeTask.request.url
        guard let url, url.scheme == Self.handlerScheme else {
            urlSchemeTask.didFailWithError(HandlerError.missingCID)
            return
        }

        let cid = url.absoluteString
            .replacingOccurrences(of: "\(Self.handlerScheme):", with: "")

        finishTaskWithImage(url: url, cid: cid, urlSchemeTask: urlSchemeTask)
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    // MARK: - Private

    private func finishTaskWithImage(url: URL, cid: String, urlSchemeTask: WKURLSchemeTask) {
        Task {
            switch await embeddedImageProvider.getEmbeddedAttachment(cid: cid) {
            case .ok(let image):
                let response = URLResponse(
                    url: url,
                    mimeType: image.mime,
                    expectedContentLength: image.data.count,
                    textEncodingName: nil
                )
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(image.data)
                urlSchemeTask.didFinish()
            case .error(let error):
                urlSchemeTask.didFailWithError(error)
            }
        }
    }
}

extension ProtonError: Error {}
