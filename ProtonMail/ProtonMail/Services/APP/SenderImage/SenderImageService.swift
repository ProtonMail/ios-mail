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

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func fetchSenderImage(
        email: String,
        isDarkMode: Bool,
        size: SenderImageRequest.Size? = .small,
        bimiSelector: String? = nil,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let request = SenderImageRequest(
            email: email,
            isDarkMode: isDarkMode,
            size: size,
            bimiSelector: bimiSelector
        )

        do {
            if let cacheImage = try dependencies.imageCache.senderImage(forURL: request.path) {
                completion(.success(cacheImage))
            } else {
                fetchImageFromBE(request: request, completion: completion)
            }
        } catch {
            completion(.failure(error))
        }
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
        let imageCache: SenderImageCache

        init(apiService: APIService, imageCache: SenderImageCache = .shared) {
            self.apiService = apiService
            self.imageCache = imageCache
        }
    }

    enum SenderImageServiceError: Error {
        case invalidState
        case responseIsNotAnImage
        case requestError(NSError)
    }
}
