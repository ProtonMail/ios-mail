// Copyright (c) 2022 Proton AG
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

import Alamofire
import LifetimeTracker
import ProtonCore_Services
import SwiftSoup

class ImageProxy: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    private static let imageCache = Cache<URL, RemoteImage>(
        totalCostLimit: Constants.ImageProxy.cacheMemoryLimitInBytes
    )

    private let dependencies: Dependencies

    // used for reading and deleting downloaded files
    // concurrent for optimum performance
    private let downloadCompletionQueue = DispatchQueue.global()

    // used for modifying the HTML document as well as combining fetched tracker info into a dictionary
    // serial for thread safety
    private let processingQueue = DispatchQueue(label: "com.protonmail.ImageProxy")

    private let recognizedImageURLPrefixes: [String] = ["http", "https", "www"]

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        trackLifetime()
    }

    static func purgeCache() {
        imageCache.purge()
    }

    func process(body: String) throws -> ImageProxyOutput {
        if Thread.isMainThread {
            assertionFailure("Do not run this method on the main thread")
        }

        let fullHTMLDocument = try SwiftSoup.parse(body)
        let imgs = try fullHTMLDocument.select("img")
        let dispatchGroup = DispatchGroup()

        var failedRequests: [UUID: URL] = [:]
        var trackers: [String: Set<URL>] = [:]

        let remoteElements: [(Element, URL)] = imgs.compactMap { img in
            guard
                let src = try? img.attr("src"),
                recognizedImageURLPrefixes.contains(where: { src.starts(with: $0) }),
                let srcURL = URL(string: src)
            else {
                return nil
            }

            dispatchGroup.enter()
            return (img, srcURL)
        }

        guard !remoteElements.isEmpty else {
            let summary = TrackerProtectionSummary(failedRequests: [:], trackers: [:])
            return ImageProxyOutput(processedBody: body, summary: summary)
        }

        for (img, srcURL) in remoteElements {
            fetchRemoteImage(srcURL: srcURL) { result in
                self.processingQueue.sync {
                    defer {
                        dispatchGroup.leave()
                    }

                    do {
                        let remoteImage = try result.get()
                        let encodedData = remoteImage.data.base64EncodedString()
                        self.setSrc(of: img, to: "data:\(remoteImage.contentType ?? "");base64,\(encodedData)")

                        if let trackerProvider = remoteImage.trackerProvider {
                            var urlsFromProvider = trackers[trackerProvider] ?? []
                            urlsFromProvider.insert(srcURL)
                            trackers[trackerProvider] = urlsFromProvider
                        }
                    } catch {
                        let uuid = self.markElementForFurtherReloadAndBlockLoadingTheImage(img)
                        failedRequests[uuid] = srcURL
                    }
                }
            }
        }

        dispatchGroup.wait()

        fullHTMLDocument.outputSettings().prettyPrint(pretty: false)
        let processedBody = try fullHTMLDocument.outerHtml()
        let summary = TrackerProtectionSummary(failedRequests: failedRequests, trackers: trackers)
        return ImageProxyOutput(processedBody: processedBody, summary: summary)
    }

    private func fetchRemoteImage(srcURL: URL, completion: @escaping (Result<RemoteImage, Error>) -> Void) {
        if let cachedRemoteImage = Self.imageCache[srcURL] {
            completion(.success(cachedRemoteImage))
            return
        }

        let remoteURL = proxyURL(for: srcURL)
        let destinationURL = temporaryLocalURL()

        dependencies.apiService.download(
            byUrl: remoteURL,
            destinationDirectoryURL: destinationURL,
            headers: nil,
            authenticated: true,
            customAuthCredential: nil,
            nonDefaultTimeout: nil,
            retryPolicy: .userInitiated,
            downloadTask: nil
        ) { response, _, error in
            self.downloadCompletionQueue.async {
                defer {
                    try? FileManager.default.removeItem(at: destinationURL)
                }

                guard let httpURLResponse = response as? HTTPURLResponse else {
                    completion(.failure(error ?? ImageProxyError.invalidState))
                    return
                }

                let result: Result<RemoteImage, Error>
                do {
                    let data = try Data(contentsOf: destinationURL)

                    // this is a more direct way of checking the result than parsing errors from the response
                    guard UIImage(data: data) != nil else {
                        throw ImageProxyError.responseIsNotAnImage
                    }

                    let remoteImage = self.remoteImage(from: data, headers: httpURLResponse.headers)
                    Self.imageCache[srcURL] = remoteImage
                    result = .success(remoteImage)
                } catch {
                    result = .failure(error)
                }

                completion(result)
            }
        }
    }

    private func proxyURL(for url: URL) -> String {
        let baseURL = dependencies.apiService.doh.getCurrentlyUsedHostUrl()
        let encodedImageURL: String = url
            .absoluteString
            .addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? url.absoluteString
        return "\(baseURL)/core/v4/images?Url=\(encodedImageURL)"
    }

    private func temporaryLocalURL() -> URL {
        let directory = FileManager
            .default
            .temporaryDirectory
            .appendingPathComponent("proxy", isDirectory: true)
        let pathComponent = UUID().uuidString
        return directory.appendingPathComponent(pathComponent)
    }

    private func remoteImage(from data: Data, headers: HTTPHeaders) -> RemoteImage {
        let contentType = determineContentType(headers: headers)
        let trackerProvider = headers["x-pm-tracker-provider"]
        return RemoteImage(contentType: contentType, data: data, trackerProvider: trackerProvider)
    }

    private func determineContentType(headers: HTTPHeaders) -> String? {
        guard let contentType = headers["Content-Type"] else {
            assertionFailure("Content-Type not declared")
            return nil
        }

        if contentType.components(separatedBy: "/").first != "image" {
            assertionFailure("\(contentType) does not describe an image")
        }

        return contentType
    }

    private func setSrc(of img: Node, to value: String) {
        // based on the inspection of the implementation of this method, it should never throw
        do {
            try img.attr("src", value)
        } catch {
            assertionFailure("\(error)")
        }
    }

    /*
     If the Image Proxy cannot fetch data from an src URL of a given img element, it will:
     - generate a UUID
     - overwrite the src of the element with the UUID to prevent loading without protection
        (<img src=\"E621E1F8-C36C-495A-93FC-0C247A3E6E5F\"></img>)
     - store the UUID and the original src URL in the `failedRequests` dictionary
     - return the `failedRequests` dictionary as a part of `TrackerProtectionSummary`

     The caller can then replace the UUIDs with the URLs to load images without protection:
     <img src=\"E621E1F8-C36C-495A-93FC-0C247A3E6E5F\"></img> -> <img src=\"https://example.com/tracker.png\"></img>.
     */
    private func markElementForFurtherReloadAndBlockLoadingTheImage(_ img: Node) -> UUID {
        let uuid = Environment.uuid()
        setSrc(of: img, to: uuid.uuidString)
        return uuid
    }
}

extension ImageProxy {
    struct Dependencies {
        let apiService: APIService
    }
}
