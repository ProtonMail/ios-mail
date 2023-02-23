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

#if DEBUG
    // needed for tests to be deterministic
    var predefinedUUIDForURL: ((UnsafeRemoteURL) -> UUID)?
#endif

    private let imageCache = ImageProxyCache.shared

    private let dependencies: Dependencies

    // used for reading and deleting downloaded files
    // concurrent for optimum performance
    private let parallelQueue = DispatchQueue.global()

    // used for modifying the HTML document as well as combining fetched tracker info into a dictionary
    // serial for thread safety
    private let processingQueue = DispatchQueue(label: "com.protonmail.ImageProxy")

    private let attributesThatCanContainRemoteURLs = [
        "background",
        "href",
        "poster",
        "src",
        "srcset",
        "style",
        "xlink:href"
    ]

    private let remoteURLRegex: NSRegularExpression = {
        // For a URL to point to a remote image, it has to begin with one of these.
        // It's safe to ignore URLs such as `<img src="local.png"/>.
        // Also we want to skip URLs with `cid` and `data` schemes.
        let remoteURLPrefixes: [String] = [
            "http",
            "https",
            "//" /* https://stackoverflow.com/questions/550038/is-it-valid-to-replace-http-with-in-a-script-src-http */
        ]

        let remoteURLsDisjunction = remoteURLPrefixes.joined(separator: "|")

        do {
            return try NSRegularExpression(
                pattern: "[=\\s'\"(]?((\(remoteURLsDisjunction))[^\\s'\")]+)",
                options: .caseInsensitive
            )
        } catch {
            fatalError("\(error)")
        }
    }()

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        trackLifetime()
    }

    func dryRun(body: String, delegate: ImageProxyDelegate) throws {
        let fullHTMLDocument = try SwiftSoup.parse(body)
        let unsafeRemoteURLs = try replaceRemoteURLsWithUUIDs(in: fullHTMLDocument).keys

        var trackers: [String: Set<UnsafeRemoteURL>] = [:]

        let dispatchGroup = DispatchGroup()

        for unsafeURL in unsafeRemoteURLs {
            dispatchGroup.enter()

            fetchTrackerInformation(from: unsafeURL) { [weak self] result in
                guard let self = self else {
                    dispatchGroup.leave()
                    return
                }

                self.processingQueue.async {
                    defer {
                        dispatchGroup.leave()
                    }

                    do {
                        if let trackerProvider = try result.get() {
                            var urlsFromProvider = trackers[trackerProvider] ?? []
                            urlsFromProvider.insert(unsafeURL)
                            trackers[trackerProvider] = urlsFromProvider
                        }
                    } catch {
                    }
                }
            }
        }

        dispatchGroup.notify(queue: processingQueue) { [weak self] in
            guard let self = self else {
                return
            }

            let summary = TrackerProtectionSummary(trackers: trackers)
            let output = ImageProxyDryRunOutput(summary: summary)
            delegate.imageProxy(self, didFinishDryRunWithOutput: output)
        }
    }

    /*
     Find all HTML fragments (attributes, style tag contents) that point to a remote image, and:
     1. generate a UUID
     2. overwrite the URL with the UUID to prevent loading without protection
        (<img src=\"E621E1F8-C36C-495A-93FC-0C247A3E6E5F\"></img>)
     3. launch a request to fetch the image through the proxy
     4. notify the delegate when the images are ready, so that they can replace the UUIDs with the data:
     <img src=\"E621E1F8-C36C-495A-93FC-0C247A3E6E5F\"></img> -> <img src=\"https://example.com/tracker.png\"></img>.
     */
    func process(body: String, delegate: ImageProxyDelegate) throws -> String {
        let fullHTMLDocument = try SwiftSoup.parse(body)
        let replacedURLs = try replaceRemoteURLsWithUUIDs(in: fullHTMLDocument)

        guard !replacedURLs.isEmpty else {
            return body
        }

        startFetchingRemoteImages(for: replacedURLs, notifying: delegate)

        fullHTMLDocument.outputSettings().prettyPrint(pretty: false)
        let bodyWithoutRemoteURLs = try fullHTMLDocument.outerHtml()
        return bodyWithoutRemoteURLs
    }

    /// Replaces remote URLs in the given document with UUIDs.
    ///
    /// If the same URL occurs multiple times in the string, each occurrence will be replaced with a different UUID.
    ///
    /// All UUIDs corresponding to the same URL are collected in a set, to avoid fetching the same URL multiple times.
    ///
    /// In the returned dictionary:
    /// - key: a remote URL that has been replaced
    /// - value: a set of UUIDs that have replaced the occurrences of that URL
    private func replaceRemoteURLsWithUUIDs(in document: Document) throws -> [UnsafeRemoteURL: Set<UUID>] {
        var uuidReplacementsForURLs: [UnsafeRemoteURL: Set<UUID>] = [:]

        for attribute in attributesThatCanContainRemoteURLs {
            let selector = cssSelector(for: attribute)
            let elements = try document.select(selector)

            for element in elements {
                let attributeValue = try element.attr(attribute)
                let (strippedAttributeValue, replacements) = replaceRemoteURLsWithUUIDs(in: attributeValue)

                if !replacements.isEmpty {
                    try element.attr(attribute, strippedAttributeValue)

                    uuidReplacementsForURLs.merge(replacements) { accumulatingSet, newSet in
                        accumulatingSet.union(newSet)
                    }
                }
            }
        }

        let styleElements = try document.select("style")

        for element in styleElements {
            let style = try element.html()
            let (strippedStyle, replacements) = replaceRemoteURLsWithUUIDs(in: style)

            if !replacements.isEmpty {
                try element.html(strippedStyle)

                uuidReplacementsForURLs.merge(replacements) { accumulatingSet, newSet in
                    accumulatingSet.union(newSet)
                }
            }
        }

        return uuidReplacementsForURLs
    }

    /// Replaces remote URLs in the given string with UUIDs.
    ///
    /// If the same URL occurs multiple times in the string, each occurrence will be replaced with a different UUID.
    ///
    /// All UUIDs corresponding to the same URL are collected in a set, to avoid fetching the same URL multiple times.
    ///
    /// - returns: A tuple: the incoming string with the URLs replaced and a dictionary of replacements.
    ///
    /// In the returned dictionary:
    /// - key - a remote URL that has been replaced
    /// - value - a set of UUIDs that have replaced the occurrences of that URL
    private func replaceRemoteURLsWithUUIDs(in string: String) -> (String, [UnsafeRemoteURL: Set<UUID>]) {
        var strippedString = string
        var uuidReplacementsForURLs: [UnsafeRemoteURL: Set<UUID>] = [:]

        while let match = remoteURLRegex.firstMatch(in: strippedString, range: strippedString.fullNSRange) {
            guard match.numberOfRanges > 1 else {
                assertionFailure()
                break
            }

            let urlNSRange = match.range(at: 1)

            guard let urlRange = Range(urlNSRange, in: strippedString) else {
                assertionFailure()
                break
            }

            let unsafeURL = UnsafeRemoteURL(value: strippedString[urlRange])

#if DEBUG
            let uuid = predefinedUUIDForURL?(unsafeURL) ?? UUID()
#else
            let uuid = UUID()
#endif

            strippedString.replaceSubrange(urlRange, with: uuid.uuidString)

            var uuidsReplacingTheUnsafeURL = uuidReplacementsForURLs[unsafeURL] ?? []
            uuidsReplacingTheUnsafeURL.insert(uuid)
            uuidReplacementsForURLs[unsafeURL] = uuidsReplacingTheUnsafeURL
        }

        return (strippedString, uuidReplacementsForURLs)
    }

    /// Constructs a CSS selector based on an HTML attribute that we want to find.
    ///
    /// We can't simply rely on "[\(attribute)]" in every case - sometimes we need to narrow the selection down to avoid finding URLs which are not remote image URLs.
    private func cssSelector(for attribute: String) -> String {
        switch attribute {
        case "src":
            return "[src]:not([src^=\"cid\"]):not([src^=\"data\"])" // skip embedded images
        case "href", "xlink:href":
            return "image[\(attribute)]" // href might point to an image inside an SVG, but we don't want to touch <a href="..."/>
        default:
            return "[\(attribute)]"
        }
    }

    private func startFetchingRemoteImages(
        for replacedURLs: [UnsafeRemoteURL: Set<UUID>],
        notifying delegate: ImageProxyDelegate
    ) {
        var failedUnsafeRemoteURLs: [Set<UUID>: UnsafeRemoteURL] = [:]
        var safeBase64Contents: [Set<UUID>: Base64Image] = [:]
        var trackers: [String: Set<UnsafeRemoteURL>] = [:]

        let dispatchGroup = DispatchGroup()

        for (unsafeURL, uuidsReplacingUnsafeURL) in replacedURLs {
            dispatchGroup.enter()

            fetchRemoteImage(from: unsafeURL) { [weak self] result in
                guard let self = self else {
                    dispatchGroup.leave()
                    return
                }

                self.processingQueue.async {
                    defer {
                        dispatchGroup.leave()
                    }

                    do {
                        let remoteImage = try result.get()
                        let base64Content = Base64Image(remoteImage: remoteImage)
                        safeBase64Contents[uuidsReplacingUnsafeURL] = base64Content

                        if let trackerProvider = remoteImage.trackerProvider {
                            var urlsFromProvider = trackers[trackerProvider] ?? []
                            urlsFromProvider.insert(unsafeURL)
                            trackers[trackerProvider] = urlsFromProvider
                        }
                    } catch {
                        failedUnsafeRemoteURLs[uuidsReplacingUnsafeURL] = unsafeURL
                    }
                }
            }
        }

        dispatchGroup.notify(queue: processingQueue) { [weak self] in
            guard let self = self else {
                return
            }

            let summary = TrackerProtectionSummary(trackers: trackers)
            let output = ImageProxyOutput(
                failedUnsafeRemoteURLs: failedUnsafeRemoteURLs,
                safeBase64Contents: safeBase64Contents,
                summary: summary
            )
            delegate.imageProxy(self, didFinishWithOutput: output)
        }
    }

    private func fetchRemoteImage(
        from unsafeURL: UnsafeRemoteURL,
        completion: @escaping (Result<RemoteImage, Error>) -> Void
    ) {
        let safeURL = proxyURL(for: unsafeURL)
        parallelQueue.async { [weak self] in
            guard let strongSelf = self else {
                completion(.failure(ImageProxyError.selfReleased))
                return
            }
            do {
                if let cachedRemoteImage = try strongSelf.imageCache.remoteImage(forURL: safeURL) {
                    completion(.success(cachedRemoteImage))
                    return
                }
            } catch {
                strongSelf.imageCache.removeRemoteImage(forURL: safeURL)
                assertionFailure("\(error)")
            }
            let destinationURL = strongSelf.temporaryLocalURL()
            strongSelf.dependencies.apiService.download(
                byUrl: safeURL.value,
                destinationDirectoryURL: destinationURL,
                headers: nil,
                authenticated: true,
                customAuthCredential: nil,
                nonDefaultTimeout: nil,
                retryPolicy: .userInitiated,
                downloadTask: nil
            ) { [weak self] response, _, error in
                self?.parallelQueue.async { [weak self] in
                    defer {
                        try? FileManager.default.removeItem(at: destinationURL)
                    }

                    guard let self = self else {
                        return
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
                        self.cacheRemoteImage(remoteImage, for: safeURL)
                        result = .success(remoteImage)
                    } catch {
                        result = .failure(error)
                    }

                    completion(result)
                }
            }
        }
    }

    private func fetchTrackerInformation(
        from unsafeURL: UnsafeRemoteURL,
        completion: @escaping (Result<String?, Error>) -> Void
    ) {
        let request = ImageProxyRequest(unsafeURL: unsafeURL, dryRun: true)

        dependencies.apiService.perform(
            request: request,
            callCompletionBlockUsing: .immediateExecutor
        ) { task, result in
            guard let httpURLResponse = task?.response as? HTTPURLResponse else {
                completion(.failure(result.error ?? task?.error ?? ImageProxyError.invalidState))
                return
            }

            let trackerProvider = httpURLResponse.headers["x-pm-tracker-provider"]
            completion(.success(trackerProvider))
        }
    }

    private func proxyURL(for unsafeURL: UnsafeRemoteURL) -> SafeRemoteURL {
        let baseURL = dependencies.apiService.doh.getCurrentlyUsedHostUrl()
        let request = ImageProxyRequest(unsafeURL: unsafeURL, dryRun: false)
        return SafeRemoteURL(value: "\(baseURL)\(request.path)")
    }

    private func temporaryLocalURL() -> URL {
        let directory = FileManager
            .default
            .temporaryDirectory
            .appendingPathComponent("proxy", isDirectory: true)
        let pathComponent = UUID().uuidString
        return directory.appendingPathComponent(pathComponent)
    }

    private func cacheRemoteImage(_ remoteImage: RemoteImage, for safeURL: SafeRemoteURL) {
        do {
            try self.imageCache.setRemoteImage(remoteImage, forURL: safeURL)
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
