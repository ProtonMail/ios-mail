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

    private let dependencies: Dependencies

    // used for reading and deleting downloaded files
    // concurrent for optimum performance
    private let downloadCompletionQueue = DispatchQueue.global()

    // used for modifing the HTML document as well as combining fetched tracker info into a dictionary
    // serial for thread safety
    private let processingQueue = DispatchQueue(label: "com.protonmail.ImageProxy")

    private let recognizedImageURLPrefixes: [String] = ["http", "https", "www"]

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        trackLifetime()
    }

    func process(body: String) throws -> ImageProxyOutput {
        if Thread.isMainThread {
            assertionFailure("Do not run this method on the main thread")
        }

        let fullHTMLDocument = try SwiftSoup.parse(body)
        let imgs = try fullHTMLDocument.select("img")
        let dispatchGroup = DispatchGroup()

        var trackers: [String: Set<URL>] = [:]

        for img in imgs {
            guard
                let src = try? img.attr("src"),
                recognizedImageURLPrefixes.contains(where: { src.starts(with: $0) }),
                let srcURL = URL(string: src)
            else {
                continue
            }

            dispatchGroup.enter()

            fetchRemoteImage(srcURL: srcURL) { result in
                self.processingQueue.sync {
                    defer {
                        dispatchGroup.leave()
                    }

                    do {
                        let remoteImage = try result.get()
                        try img.attr("src", "data:\(remoteImage.contentType ?? "");base64,\(remoteImage.data)")

                        if let trackerProvider = remoteImage.trackerProvider {
                            var urlsFromProvider = trackers[trackerProvider] ?? []
                            urlsFromProvider.insert(srcURL)
                            trackers[trackerProvider] = urlsFromProvider
                        }
                    } catch {
                        /*
                         The latest decision by product is to continue loading the images in case the proxy fails
                         or is unreachable. Currently, if the user disabled the autoloading of remote images,
                         the banner will show up, but will not notify them of the details of the risk.
                         In the future we'll need to update the logic in this class to properly communicate that
                         proceeding won't involve the proxy and as such will pose a threat.
                         */
                    }
                }
            }
        }

        dispatchGroup.wait()

        fullHTMLDocument.outputSettings().prettyPrint(pretty: false)
        let processedBody = try fullHTMLDocument.outerHtml()
        let summary = TrackerProtectionSummary(trackers: trackers)
        return ImageProxyOutput(processedBody: processedBody, summary: summary)
    }

    private func fetchRemoteImage(srcURL: URL, completion: @escaping (Result<RemoteImage, Error>) -> Void) {
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
        return "\(baseURL)/core/v4/images?Url=\(url)"
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
        let encodedData = data.base64EncodedString()
        let contentType = determineContentType(headers: headers)
        let trackerProvider = headers["x-pm-tracker-provider"]
        return RemoteImage(contentType: contentType, data: encodedData, trackerProvider: trackerProvider)
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
}

extension ImageProxy {
    struct Dependencies {
        let apiService: APIService
    }
}
