// Copyright (c) 2023 Proton Technologies AG
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

import Foundation
import ProtonCore_Services
import SDWebImage

final class SenderImageService {
    private let dependencies: Dependencies
    /// used to store the callbacks of the same url.
    private var senderImageCallbackMap: [String: [SenderImageCompletion]] = [:]
    /// used to access the map of the callbacks
    private let callBacksAccessQueue = DispatchQueue(label: "me.proton.senderImageService")

    typealias SenderImageCompletion = (Result<Data, Error>) -> Void

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func fetchSenderImage(
        email: String,
        isDarkMode: Bool,
        size: SenderImageRequest.Size? = .small,
        bimiSelector: String? = nil,
        completion: @escaping SenderImageCompletion
    ) {
        let request = SenderImageRequest(
            email: email,
            isDarkMode: isDarkMode,
            size: size,
            bimiSelector: bimiSelector
        )
        let key = request.path

        var shouldReturn = false
        callBacksAccessQueue.sync {
            if var callbacks = self.senderImageCallbackMap[key] {
                callbacks.append(completion)
                self.senderImageCallbackMap[key] = callbacks
                shouldReturn = true
            } else {
                self.senderImageCallbackMap[key] = [completion]
            }
        }

        guard !shouldReturn else {
            return
        }

        do {
            if let cachedImage = try self.dependencies.imageCache.senderImage(forURL: key) {
                self.propagateResultToAllCallbacks(key: key, result: .success(cachedImage))
            } else {
                if self.dependencies.internetStatusProvider.currentStatus != .notConnected {
                    self.fetchImageFromBE(request: request) { result in
                        self.propagateResultToAllCallbacks(key: key, result: result)
                    }
                } else {
                    // In offline, try to fetch the cached image with different view mode.
                    try self.tryToLoadImageWithDifferentModeFromCache(originalKey: key, originalRequest: request)
                }
            }
        } catch {
            self.dependencies.imageCache.removeSenderImage(forURL: key)
            self.propagateResultToAllCallbacks(key: key, result: .failure(error))
        }
    }

    private func tryToLoadImageWithDifferentModeFromCache(
        originalKey: String,
        originalRequest: SenderImageRequest
    ) throws {
        let request = SenderImageRequest(
            email: originalRequest.emailAddress,
            isDarkMode: !originalRequest.isDarkMode,
            size: originalRequest.size,
            bimiSelector: originalRequest.bimiSelector
        )
        if let cachedImage = try dependencies.imageCache.senderImage(forURL: request.path) {
            self.propagateResultToAllCallbacks(key: originalKey, result: .success(cachedImage))
        } else {
            throw SenderImageServiceError.noCachedImageFound
        }
    }

    private func propagateResultToAllCallbacks(key: String, result: Result<Data, Error>) {
        var callbacks: [SenderImageService.SenderImageCompletion] = []
        callBacksAccessQueue.sync {
            if let value = self.senderImageCallbackMap[key] {
                callbacks = value
                self.senderImageCallbackMap.removeValue(forKey: key)
            }
        }
        callbacks.forEach { $0(result) }
    }

    private func requestUrl(request: SenderImageRequest) -> String {
        let baseURL = dependencies.apiService.dohInterface.getCurrentlyUsedHostUrl()
        return "\(baseURL)\(request.path)"
    }

    private func fetchImageFromBE(request: SenderImageRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        let url = requestUrl(request: request)
        let tempUrl: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("senderImage", isDirectory: true)
            .appendingPathComponent(UUID().uuidString)
        dependencies.apiService.download(
            byUrl: url,
            destinationDirectoryURL: tempUrl,
            headers: nil,
            authenticated: true,
            customAuthCredential: nil,
            nonDefaultTimeout: nil,
            retryPolicy: .userInitiated,
            downloadTask: nil,
            downloadCompletion: { response, _, error in
                defer {
                    try? FileManager.default.removeItem(at: tempUrl)
                }

                guard let httpURLResponse = response as? HTTPURLResponse,
                      httpURLResponse.statusCode == 200,
                      error == nil else {
                    completion(.failure(error ?? SenderImageServiceError.invalidState))
                    return
                }

                do {
                    let data = try Data(contentsOf: tempUrl)
                    // TODO: Render SVG file. iOS does not have native support to render it.
                    guard UIImage(data: data) != nil else {
                        throw SenderImageServiceError.responseIsNotAnImage
                    }
                    try self.cacheSenderImage(url: request.path, data: data)
                    completion(.success(data))
                } catch {
                    completion(.failure(error))
                }
            }
        )
    }

    private func cacheSenderImage(url: String, data: Data) throws {
        try dependencies.imageCache.setSenderImage(data, forURL: url)
    }

    struct Dependencies {
        let apiService: APIService
        let internetStatusProvider: InternetConnectionStatusProviderProtocol
        let imageCache: SenderImageCache

        init(
            apiService: APIService,
            internetStatusProvider: InternetConnectionStatusProviderProtocol,
            imageCache: SenderImageCache = .shared
        ) {
            self.apiService = apiService
            self.internetStatusProvider = internetStatusProvider
            self.imageCache = imageCache
        }
    }

    enum SenderImageServiceError: Error {
        case invalidState
        case responseIsNotAnImage
        case noCachedImageFound
    }
}
