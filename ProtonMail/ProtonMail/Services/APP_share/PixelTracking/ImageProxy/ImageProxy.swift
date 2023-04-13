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

import ProtonCore_Services

class ImageProxy {
    #if DEBUG
    // needed for tests to be deterministic
    var predefinedUUIDForURL: ((UnsafeRemoteURL) -> UUID)?
    #endif

    #if !APP_EXTENSION
    private let imageCache = ImageProxyCache.shared
    #endif

    private let dependencies: Dependencies

    // used for reading and deleting downloaded files
    // concurrent for optimum performance
    private let parallelQueue = DispatchQueue.global()

    private weak var delegate: ImageProxyDelegate?
    private var remoteImageCallbackMap: [URL: [RemoteImageCallback]] = [:]

    typealias RemoteImageCallback = (Result<RemoteImage, Error>) -> Void

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func set(delegate: ImageProxyDelegate) {
        self.delegate = delegate
    }

    ///  Fetch the content of the url with the proxy.
    ///
    ///  If the resource is fetched before,  cached data we be returned.
    ///
    /// - Parameters:
    ///   - url: resource url
    ///   - completion: resource fetch result
    func fetchRemoteImageIfNeeded(url: URL, completion: @escaping RemoteImageCallback) {
        let action = {
            // Stops the request is being triggered multiple times to the same URL in a short time.
            if var callbacks = self.remoteImageCallbackMap[url] {
                callbacks.append(completion)
                self.remoteImageCallbackMap[url] = callbacks
                return
            } else {
                self.remoteImageCallbackMap[url] = [completion]
            }

            do {
                let unsafeURL = try self.removeProtonPrefix(url: url)
                self.fetchRemoteImage(from: unsafeURL) { result in
                    DispatchQueue.main.async {
                        if let callbacks = self.remoteImageCallbackMap[url] {
                            callbacks.forEach { $0(result) }
                            self.remoteImageCallbackMap.removeValue(forKey: url)
                        }
                    }
                }
            } catch {
                if let callbacks = self.remoteImageCallbackMap[url] {
                    callbacks.forEach { $0(.failure(error)) }
                    self.remoteImageCallbackMap.removeValue(forKey: url)
                }
            }
        }

        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async {
                action()
            }
        }
    }

    func fetchRemoteImageTrackerInfo(url: URL, completion: @escaping (Result<String?, Error>) -> Void) {
        fetchTrackerInformation(from: .init(value: url.absoluteString), completion: completion)
    }

    func passTrackerSummaryToView(summary: TrackerProtectionSummary?, hasFailedRequest: Bool) {
        delegate?.imageProxy(self, output: .init(hasEncounteredErrors: hasFailedRequest, summary: summary))
    }

    // swiftlint:disable:next function_body_length
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
            #if !APP_EXTENSION
            do {
                if let cachedRemoteImage = try strongSelf.imageCache.remoteImage(forURL: safeURL) {
                    completion(.success(cachedRemoteImage))
                    return
                }
            } catch {
                strongSelf.imageCache.removeRemoteImage(forURL: safeURL)
                assertionFailure("\(error)")
            }
            #endif
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

    private func removeProtonPrefix(url: URL) throws -> UnsafeRemoteURL {
        let prefixToBeRemoved = "proton-"
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let scheme = components.scheme else {
            throw ImageProxyError.schemeNotFound
        }
        guard scheme.hasPrefix(prefixToBeRemoved) else {
            throw ImageProxyError.schemeHasNoPrefix
        }
        let newScheme = String(scheme.dropFirst(prefixToBeRemoved.count))
        components.scheme = newScheme
        guard let originalURL = components.url else {
            throw ImageProxyError.originalUrlIsNil
        }
        return .init(value: originalURL.absoluteString)
    }

    private func fetchTrackerInformation(
        from unsafeURL: UnsafeRemoteURL,
        completion: @escaping (Result<String?, Error>) -> Void
    ) {
        guard let url = URL(string: unsafeURL.value) else {
            completion(.failure(ImageProxyError.schemeNotFound))
            return
        }
        do {
            let newUnsafeUrl = try removeProtonPrefix(url: url)
            let request = ImageProxyRequest(unsafeURL: newUnsafeUrl, dryRun: true)

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
        } catch {
            completion(.failure(error))
        }
    }

    private func proxyURL(for unsafeURL: UnsafeRemoteURL) -> SafeRemoteURL {
        let baseURL = dependencies.apiService.dohInterface.getCurrentlyUsedHostUrl()
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
        #if !APP_EXTENSION
        do {
            try imageCache.setRemoteImage(remoteImage, forURL: safeURL)
        } catch {
            assertionFailure("\(error)")
        }
        #endif
    }
}

extension ImageProxy {
    struct Dependencies {
        let apiService: APIService
    }
}
