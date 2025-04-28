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
import TryCatch
import WebKit

public final class CIDSchemeHandler: NSObject, WKURLSchemeHandler {
    private let embeddedImageProvider: EmbeddedImageProvider
    private var urlSchemeActiveTasks = Set<ObjectIdentifier>()
    private let queue = DispatchQueue(label:  "\(Bundle.defaultIdentifier).\(CIDSchemeHandler.self)")

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
        queue.sync { _ = urlSchemeActiveTasks.insert(ObjectIdentifier(urlSchemeTask)) }
        let url = urlSchemeTask.request.url
        guard let url, url.scheme == Self.handlerScheme else {
            urlSchemeTask.didFailWithError(HandlerError.missingCID)
            return
        }

        let cid = url.absoluteString
            .replacingOccurrences(of: "\(Self.handlerScheme):", with: "")

        finishTaskWithImage(url: url, cid: cid, urlSchemeTask: urlSchemeTask)
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        AppLogger.log(message: "webView stop urlSchemeTask", category: .conversationDetail)
        queue.sync { _ = urlSchemeActiveTasks.remove(ObjectIdentifier(urlSchemeTask)) }
    }

    // MARK: - Private

    private func performOnUrlSchemeActiveTasks<T>(_ block: @escaping (inout Set<ObjectIdentifier>) -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: PerformOnUrlSchemeActiveTasksError.noSelf)
                    return
                }
                let result = block(&self.urlSchemeActiveTasks)
                continuation.resume(returning: result)
            }
        }
    }

    private func finishTaskWithImage(url: URL, cid: String, urlSchemeTask: WKURLSchemeTask) {
        Task {
            switch await embeddedImageProvider.getEmbeddedAttachment(cid: cid) {
            case .ok(let image):
                let message = "embedded image mime type: \(image.mime), content length: \(image.data.count)"
                AppLogger.logTemporarily(message: message, category: .conversationDetail)
                await handleImage(image, url: url, urlSchemeTask: urlSchemeTask)
            case .error(let error):
                let message = "cid: \(cid), error: \(error)"
                AppLogger.log(message: message, category: .composer, isError: true)
                urlSchemeTask.didFailWithError(error)
            }
            let taskId = ObjectIdentifier(urlSchemeTask)
            try await performOnUrlSchemeActiveTasks { activeTasks in _ = activeTasks.remove(taskId) }
        }
    }

    private func handleImage(_ image: EmbeddedAttachmentInfo, url: URL, urlSchemeTask: WKURLSchemeTask) async {
        let taskId = ObjectIdentifier(urlSchemeTask)
        let response = URLResponse(
            url: url,
            mimeType: image.mime,
            expectedContentLength: image.data.count,
            textEncodingName: nil
        )
        do {
            guard try await performOnUrlSchemeActiveTasks({ activeTasks in activeTasks.contains(taskId) }) else {
                AppLogger.log(message: "urlSchemeTask not active anymore", category: .conversationDetail)
                return
            }
            try ObjC.catchException {
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(image.data)
                urlSchemeTask.didFinish()
            }
        } catch {
            AppLogger.logTemporarily(message: "\(error)", category: .conversationDetail, isError: true)
        }
    }

    enum PerformOnUrlSchemeActiveTasksError: Error {
        case noSelf
    }
}

extension ProtonError: Error {}
