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

import Foundation
import protocol ProtonCore_Services.APIService

/// Singleton that centralizes all file downloads. It keeps a reference to all downloads in progress
/// and notifies all observers whenever the task finishes.
final class DownloadService {
    static let shared = DownloadService()

    private let serialQueue = DispatchQueue(label: "me.proton.mail.DownloadService")
    private let dependencies: Dependencies

    private var activeDownloads = [URL: UrlDownload]()

    init(dependencies: Dependencies = Dependencies()) {
        self.dependencies = dependencies
    }

    /// Downloads the requested `url` to the specific destination. If a file already exists in
    /// the `destinationFile`, it returns that file immediately.
    ///
    /// All downloads centralised through `DownloadService` will be referenced. If a
    /// requested `url` resource is already being downloaded, no new request will be
    /// triggered unless more than a certain amount of seconds have passed (`retryThresholdInSeconds`).
    /// Instead the completion method will be added to a list of subscribers that
    /// will be notified when the download finishes.
    ///
    /// An `APIService` is required because it is the one managing the authentication credentials
    /// for he request to succeed.
    ///
    /// Currenlty there is no download progress provided by the Core API.
    ///
    /// - Parameters:
    ///   - url: url of the resource to be downloaded.
    ///   - destinationFile: url of the local destination of the downloaded resource.
    ///   - apiService: API to be used to request the download. This parameter is
    ///   required because it manages the authentication logic required for the success of the request.
    ///   - completion: callback called whenever the resource is available in a local file.
    func download(
        url: URL,
        to destinationFile: URL,
        apiService: APIService,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard !dependencies.fileManager.fileExists(atPath: destinationFile.path) else {
            completion(.success(destinationFile))
            return
        }

        var isUrlDownloading: Bool = false
        serialQueue.sync {
            if var activeUrlDownload = activeDownloads[url], !activeUrlDownload.retryDownload {
                activeUrlDownload.observers.append(completion)
                activeDownloads[url] = activeUrlDownload
                isUrlDownloading = true
            } else {
                activeDownloads[url] = UrlDownload(
                    url: url,
                    observer: completion,
                    retryThresholdInSeconds: dependencies.retryThresholdInSeconds
                )
            }
        }

        if !isUrlDownloading {
            startDownload(url: url, to: destinationFile, apiService: apiService) { [weak self] result in
                var observers = [UrlDownload.Observer]()
                self?.serialQueue.sync {
                    observers = self?.activeDownloads.removeValue(forKey: url)?.observers ?? []
                }
                for observer in observers {
                    observer(result)
                }
            }
        }
    }

    private func startDownload(
        url: URL,
        to destinationFile: URL,
        apiService: APIService,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // TODO: Improvement https://jira.protontech.ch/browse/MAILIOS-2843
        apiService.download(
            byUrl: url.absoluteString,
            destinationDirectoryURL: destinationFile,
            headers: .empty,
            authenticated: true,
            customAuthCredential: nil,
            nonDefaultTimeout: nil,
            retryPolicy: .background,
            downloadTask: nil,
            downloadCompletion: { _, downloadedFileUrl, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let downloadedFile = downloadedFileUrl else {
                    completion(.failure(CocoaError.error(.fileNoSuchFile)))
                    return
                }
                completion(.success(downloadedFile))
            }
        )
    }
}

extension DownloadService {
    struct Dependencies {
        let fileManager: FileManager
        /// Number of seconds that have to pass since a request was started to retry that request again
        let retryThresholdInSeconds: TimeInterval

        init(fileManager: FileManager = .default, retryThresholdInSeconds: TimeInterval = 5 * 60) {
            self.fileManager = fileManager
            self.retryThresholdInSeconds = retryThresholdInSeconds
        }
    }
}

private struct UrlDownload {
    typealias Observer = (Result<URL, Error>) -> Void

    let url: URL
    var observers: [Observer]

    private let createdAt: Date
    private let retryThresholdInSeconds: TimeInterval

    /// Returns `true` if enough time has passed since the request was triggered
    var retryDownload: Bool {
        return Date().timeIntervalSince(createdAt) > retryThresholdInSeconds
    }

    init(url: URL, observer: @escaping Observer, retryThresholdInSeconds: TimeInterval) {
        self.url = url
        self.observers = [observer]
        self.createdAt = Date()
        self.retryThresholdInSeconds = retryThresholdInSeconds
    }
}
