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

import TryCatch
import WebKit
import proton_app_uniffi

final class UniversalSchemeHandler: NSObject, WKURLSchemeHandler {
    private let imageProxy: ImageProxy
    private var urlSchemeActiveTasks = Set<ObjectIdentifier>()
    private let queue = DispatchQueue(label: "\(Bundle.defaultIdentifier).\(UniversalSchemeHandler.self)")

    init(imageProxy: ImageProxy) {
        self.imageProxy = imageProxy
    }

    enum HandlerError: Error, Equatable {
        case missingURL
    }

    static let handlerSchemes: [String] = ["cid", "proton-http", "proton-https"]

    // MARK: - WKURLSchemeHandler

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        queue.sync { _ = urlSchemeActiveTasks.insert(ObjectIdentifier(urlSchemeTask)) }
        let url = urlSchemeTask.request.url
        guard let url else {
            urlSchemeTask.didFailWithError(HandlerError.missingURL)
            return
        }

        finishTaskWithImage(url: url, urlSchemeTask: urlSchemeTask)
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        AppLogger.log(message: "webView stop urlSchemeTask", category: .conversationDetail)
        queue.sync { _ = urlSchemeActiveTasks.remove(ObjectIdentifier(urlSchemeTask)) }
    }

    // MARK: - Private

    private func performOnUrlSchemeActiveTasks<T>(
        _ block: @escaping (inout Set<ObjectIdentifier>) -> T
    ) async throws -> T {
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

    private func finishTaskWithImage(url: URL, urlSchemeTask: WKURLSchemeTask) {
        let taskId = ObjectIdentifier(urlSchemeTask)

        Task {
            let result = await imageProxy.loadImage(url: url.absoluteString)

            guard try await performOnUrlSchemeActiveTasks({ activeTasks in activeTasks.contains(taskId) }) else {
                AppLogger.log(message: "urlSchemeTask not active anymore", category: .conversationDetail)
                return
            }

            switch result {
            case .ok(let image):
                handleAttachment(image, url: url, urlSchemeTask: urlSchemeTask)
            case .error(let error):
                AppLogger.log(error: error, category: .webView)
                urlSchemeTask.markAsFailedCatchingExceptions(error)
            }

            try await performOnUrlSchemeActiveTasks { activeTasks in _ = activeTasks.remove(taskId) }
        }
    }

    private func handleAttachment(_ attachment: AttachmentData, url: URL, urlSchemeTask: WKURLSchemeTask) {
        let response = URLResponse(
            url: url,
            mimeType: attachment.mime,
            expectedContentLength: attachment.data.count,
            textEncodingName: nil
        )
        do {
            try ObjC.catchException {
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(attachment.data)
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

extension AttachmentDataError: @retroactive Error {}
extension ProtonError: @retroactive Error {}

private extension WKURLSchemeTask {
    func markAsFailedCatchingExceptions(_ responseError: Error) {
        do {
            try ObjC.catchException {
                self.didFailWithError(responseError)
            }
        } catch let exceptionError {
            AppLogger.logTemporarily(message: "\(exceptionError)", category: .conversationDetail, isError: true)
        }
    }
}
