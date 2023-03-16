// Copyright (c) 2022 Proton Technologies AG
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

import WebKit

class SecureLoaderSchemeHandler: NSObject, WKURLSchemeHandler {
    let userKeys: UserKeys
    let imageProxy: ImageProxy
    var contents: WebContents?
    var loopbacks: [URL: Data] = [:]
    var latestRequest: String?
    private var shouldBeStoppedTasks: [WKURLSchemeTask] = []

    private var hasFailedRequest = false {
        didSet {
            imageProxy.passTrackerSummaryToView(
                summary: summary,
                hasFailedRequest: hasFailedRequest
            )
        }
    }
    private(set) var trackers: [String: Set<UnsafeRemoteURL>] = [:] {
        didSet {
            summary = .init(trackers: trackers)
        }
    }
    private(set) var summary: TrackerProtectionSummary? {
        didSet {
            if let summary = summary {
                imageProxy.passTrackerSummaryToView(
                    summary: summary,
                    hasFailedRequest: hasFailedRequest
                )
            }
        }
    }

    init(userKeys: UserKeys, imageProxy: ImageProxy) {
        self.userKeys = userKeys
        self.imageProxy = imageProxy
        super.init()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        if isImageRequest(urlSchemeTask: urlSchemeTask) {
            handleImageRequest(urlSchemeTask: urlSchemeTask)
        } else if isPMIncomingMailRequest(urlSchemeTask: urlSchemeTask) {
            handlePMIncomingMailRequest(urlSchemeTask: urlSchemeTask)
        } else {
            guard let url = urlSchemeTask.request.url?.absoluteURL else { return }
            let error = NSError(domain: "cache.proton.ch", code: -999)

            let contentLoadingType = contents?.contentLoadingType ?? .none
            switch contentLoadingType {
            case .proxyDryRun:
                fetchTackerInfo(url, urlSchemeTask, error)
            case .proxy:
                fetchRemoteImage(url, urlSchemeTask, error)
            case .none:
                urlSchemeTask.didFailWithError(error)
            case .direct:
                assertionFailure("Content loaded without proxy should not reach here.")
            }
        }
    }

    private func fetchTackerInfo(_ url: URL, _ urlSchemeTask: WKURLSchemeTask, _ error: NSError) {
        imageProxy.fetchRemoteImageTrackerInfo(url: url) { result in
            DispatchQueue.main.async {
                // Stop the duplicated request that is marked by webview.
                guard !self.shouldBeStoppedTasks.contains(where: { $0.request == urlSchemeTask.request }) else {
                    self.shouldBeStoppedTasks.removeAll(where: { $0.request == urlSchemeTask.request })
                    return
                }

                switch result {
                case .success(let trackerInfo):
                    self.saveFetchResult(trackerInfo: trackerInfo, url: url)
                case .failure:
                    break
                }
                urlSchemeTask.didFailWithError(error)
            }
        }
    }

    private func fetchRemoteImage(_ url: URL, _ urlSchemeTask: WKURLSchemeTask, _ error: NSError) {
        imageProxy.fetchRemoteImageIfNeeded(url: url) { result in
            DispatchQueue.main.async {
                // Stop the duplicated request this is marked by webview.
                guard !self.shouldBeStoppedTasks.contains(where: { $0.request == urlSchemeTask.request }) else {
                    self.shouldBeStoppedTasks.removeAll(where: { $0.request == urlSchemeTask.request })
                    return
                }

                switch result {
                case .success(let remoteImage):
                    self.saveFetchResult(remoteImage: remoteImage, url: url)
                    guard let url = urlSchemeTask.request.url,
                          let response = HTTPURLResponse(
                            url: url,
                            statusCode: 200,
                            httpVersion: "HTTP/2",
                            headerFields: nil
                          ) else {
                        urlSchemeTask.didFailWithError(error)
                        return
                    }
                    urlSchemeTask.didReceive(response)
                    urlSchemeTask.didReceive(remoteImage.data)
                    urlSchemeTask.didFinish()
                case .failure:
                    self.hasFailedRequest = true
                    urlSchemeTask.didFailWithError(error)
                }
            }
        }
    }

    private func saveFetchResult(remoteImage: RemoteImage, url: URL) {
        if let trackerProvider = remoteImage.trackerProvider {
            var urlsFromProvider = trackers[trackerProvider] ?? []
            urlsFromProvider.insert(.init(value: url.absoluteStringWithoutProtonPrefix()))
            trackers[trackerProvider] = urlsFromProvider
        }
    }

    private func saveFetchResult(trackerInfo: String?, url: URL) {
        if let trackerInfo = trackerInfo {
            var urlsFromProvider = trackers[trackerInfo] ?? []
            urlsFromProvider.insert(.init(value: url.absoluteStringWithoutProtonPrefix()))
            trackers[trackerInfo] = urlsFromProvider
        }
    }

    private func isPMIncomingMailRequest(urlSchemeTask: WKURLSchemeTask) -> Bool {
        guard let url = urlSchemeTask.request.url,
              let urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let scheme = urlComponent.scheme else {
            return false
        }
        return scheme.contains(HTTPRequestSecureLoader.loopbackScheme)
    }

    private func handlePMIncomingMailRequest(urlSchemeTask: WKURLSchemeTask) {
        guard let contents = self.contents,
              let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFinish()
            return
        }

        let headers: [String: String] = [
            "Content-Type": "text/html",
            "Cross-Origin-Resource-Policy": "Same",
            "Content-Security-Policy": contents.contentSecurityPolicy
        ]

        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/2",
            headerFields: headers)

        guard let response = response else {
            urlSchemeTask.didFinish()
            return
        }

        urlSchemeTask.didReceive(response)
        if let found = self.loopbacks[url] {
            urlSchemeTask.didReceive(found)
            if let target = latestRequest,
               url.absoluteString.contains(check: target) {
                latestRequest = nil
            }
        }
        urlSchemeTask.didFinish()
    }

    private func isImageRequest(urlSchemeTask: WKURLSchemeTask) -> Bool {
        guard let url = urlSchemeTask.request.url?.absoluteString else { return false }
        return url.starts(with: HTTPRequestSecureLoader.ProtonScheme.pmCache.rawValue) ||
            url.starts(with: HTTPRequestSecureLoader.imageCacheScheme)
    }

    private func handleImageRequest(urlSchemeTask: WKURLSchemeTask) {
        let error = NSError(domain: "cache.proton.ch", code: -999)
        guard let url = urlSchemeTask.request.url,
              let id = url.host else {
            urlSchemeTask.didFailWithError(error)
            return
        }
        guard
            let keyPacket = contents?.webImages?.embeddedImages.first(where: { $0.id == AttachmentID(id) })?.keyPacket
        else {
            urlSchemeTask.didFailWithError(error)
            return
        }
        guard let image = loadImageFromCache(attachmentID: id, userKeys: userKeys, keyPacket: keyPacket),
              let data = image.jpegData(compressionQuality: 1),
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/2", headerFields: nil) else {
            urlSchemeTask.didFailWithError(error)
            return
        }

        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    private func loadImageFromCache(attachmentID: String, userKeys: UserKeys, keyPacket: String) -> UIImage? {
        let path = FileManager.default.attachmentDirectory.appendingPathComponent(attachmentID)

        do {
            let encoded = try AttachmentDecrypter.decryptAndEncode(
                fileUrl: path,
                attachmentKeyPacket: keyPacket,
                userKeys: userKeys
            )
            if let data = Data(base64Encoded: encoded, options: .ignoreUnknownCharacters),
               let image = UIImage(data: data) {
                return image
            }
            return nil
        } catch {
            return nil
        }
    }

    // If the message has both embedded and remote contents, the webview reload could be triggered twice.
    // This caused the webview reloads in a short time. There will be duplicated requests that are triggered.
    // Those requests should be recored here and prevent the callback of the request to be called.
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // record the request that should be stopped.
        shouldBeStoppedTasks.append(urlSchemeTask)
    }
}

private extension URL {
    func absoluteStringWithoutProtonPrefix() -> String {
        let prefixToBeRemoved = "proton-"
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let scheme = components.scheme else {
            return absoluteString
        }
        guard scheme.hasPrefix(prefixToBeRemoved) else {
            return absoluteString
        }
        let newScheme = String(scheme.dropFirst(prefixToBeRemoved.count))
        components.scheme = newScheme
        guard let originalURL = components.url else {
            return absoluteString
        }
        return originalURL.absoluteString
    }
}
