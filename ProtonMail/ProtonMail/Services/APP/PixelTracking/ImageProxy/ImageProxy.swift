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

import LifetimeTracker
import ProtonCore_Services
import SwiftSoup

class ImageProxy: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    private let imageCache = ImageProxyCache.shared

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

    /*
     Iterate over all <img> elements that point to a remote image, and:
     1. generatie a UUID
     2. overwrite the src of the img with the UUID to prevent loading without protection
        (<img src=\"E621E1F8-C36C-495A-93FC-0C247A3E6E5F\"></img>)
     3. launch a request to fetch the image through the proxy
     4. notify the delegate when the image is ready, so that they can replace the UUIDs with the data:
     <img src=\"E621E1F8-C36C-495A-93FC-0C247A3E6E5F\"></img> -> <img src=\"https://example.com/tracker.png\"></img>.
     */
    func process(body: String, delegate: ImageProxyDelegate) throws -> String {
        let fullHTMLDocument = try SwiftSoup.parse(body)
        let imgs = try fullHTMLDocument.select("img")

        let remoteElements: [(Element, String)] = imgs.compactMap { img in
            guard
                let srcURL = try? img.attr("src"),
                recognizedImageURLPrefixes.contains(where: { srcURL.starts(with: $0) })
            else {
                return nil
            }

            return (img, srcURL)
        }

        guard !remoteElements.isEmpty else {
            return body
        }

        var failedUnsafeRemoteSrcs: Set<SrcReplacement> = []
        var safeBase64Srcs: Set<SrcReplacement> = []
        var trackers: [String: Set<String>] = [:]

        let dispatchGroup = DispatchGroup()

        for (img, srcURL) in remoteElements {
            let uuid = Environment.uuid()

            try img.attr("src", uuid.uuidString)

            dispatchGroup.enter()

            fetchRemoteImage(srcURL: srcURL) { [weak self] result in
                guard let self = self else {
                    dispatchGroup.leave()
                    return
                }

                self.processingQueue.sync {
                    defer {
                        dispatchGroup.leave()
                    }

                    do {
                        let remoteImage = try result.get()

                        let encodedData = remoteImage.data.base64EncodedString()
                        let base64Src = "data:\(remoteImage.contentType ?? "");base64,\(encodedData)"
                        let replacement = SrcReplacement(marker: uuid, value: base64Src)
                        safeBase64Srcs.insert(replacement)

                        if let trackerProvider = remoteImage.trackerProvider {
                            var urlsFromProvider = trackers[trackerProvider] ?? []
                            urlsFromProvider.insert(srcURL)
                            trackers[trackerProvider] = urlsFromProvider
                        }
                    } catch {
                        let replacement = SrcReplacement(marker: uuid, value: srcURL)
                        failedUnsafeRemoteSrcs.insert(replacement)
                    }
                }
            }
        }

        dispatchGroup.notify(queue: processingQueue) { [weak delegate] in
            let summary = TrackerProtectionSummary(trackers: trackers)
            let output = ImageProxyOutput(
                failedUnsafeRemoteSrcs: failedUnsafeRemoteSrcs,
                safeBase64Srcs: safeBase64Srcs,
                summary: summary
            )
            delegate?.imageProxy(self, didFinishWithOutput: output)
        }

        fullHTMLDocument.outputSettings().prettyPrint(pretty: false)
        let bodyWithoutRemoteURLs = try fullHTMLDocument.outerHtml()
        return bodyWithoutRemoteURLs
    }

    private func fetchRemoteImage(srcURL: String, completion: @escaping (Result<RemoteImage, Error>) -> Void) {
        let remoteURL = proxyURL(for: srcURL)

        do {
            if let cachedRemoteImage = try imageCache.remoteImage(forURL: remoteURL) {
                completion(.success(cachedRemoteImage))
                return
            }
        } catch {
            imageCache.removeRemoteImage(forURL: remoteURL)
            assertionFailure("\(error)")
        }

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

                    let remoteImage = RemoteImage(data: data, httpURLResponse: httpURLResponse)
                    self.cacheRemoteImage(remoteImage, for: remoteURL)
                    result = .success(remoteImage)
                } catch {
                    result = .failure(error)
                }

                completion(result)
            }
        }
    }

    private func proxyURL(for urlString: String) -> String {
        let baseURL = dependencies.apiService.doh.getCurrentlyUsedHostUrl()
        let encodedImageURL = urlString
            .addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? urlString
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

    private func cacheRemoteImage(_ remoteImage: RemoteImage, for remoteURL: String) {
        do {
            try self.imageCache.setRemoteImage(remoteImage, forURL: remoteURL)
        } catch {
            assertionFailure("\(error)")
        }
    }
}

extension ImageProxy {
    struct Dependencies {
        let apiService: APIService
    }
}
