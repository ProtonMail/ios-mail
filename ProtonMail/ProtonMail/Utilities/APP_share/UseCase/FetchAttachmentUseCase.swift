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
import protocol ProtonCoreDoh.DoHInterface
import protocol ProtonCoreServices.APIService

typealias FetchAttachmentUseCase = UseCase<AttachmentFile, FetchAttachment.Params>

extension FetchAttachmentUseCase {
    func execute(params: Params) async throws -> AttachmentFile {
        try await withCheckedThrowingContinuation { continuation in
            execute(params: params, callback: continuation.resume)
        }
    }
}

final class FetchAttachment: FetchAttachmentUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Params, callback: @escaping Callback) {
        let localUrl = localUrl(for: params.attachmentID)
        let remoteUrl = remoteUrl(for: params.attachmentID)
        dependencies
            .downloadService
            .download(
                url: remoteUrl,
                to: localUrl,
                apiService: dependencies.apiService
            ) { [weak self] result in
                guard let self = self else { return }
                self.executionQueue.async {
                    switch result {
                    case .success:
                        do {
                            let plaintext = try AttachmentDecrypter.decrypt(
                                fileUrl: localUrl,
                                attachmentKeyPacket: params.attachmentKeyPacket,
                                userKeys: params.userKeys
                            )
                            let attachmentFile = AttachmentFile(
                                attachmentId: params.attachmentID,
                                fileUrl: localUrl,
                                data: plaintext
                            )
                            callback(.success(attachmentFile))
                        } catch {
                            callback(.failure(error))
                        }
                    case .failure(let error):
                        callback(.failure(error))
                    }
                }
            }
    }

    private func localUrl(for attachmentID: AttachmentID) -> URL {
        return dependencies.attachmentCacheFolder.appendingPathComponent(attachmentID.rawValue)
    }

    private func remoteUrl(for attachmentID: AttachmentID) -> URL {
        let url = dependencies.doh.getCurrentlyUsedHostUrl() + "/attachments/" + attachmentID.rawValue
        // swiftlint:disable:next force_unwrapping
        return URL(string: url)!
    }
}

extension FetchAttachment {
    struct Params {
        let attachmentID: AttachmentID
        let attachmentKeyPacket: String?
        let userKeys: UserKeys
    }

    struct Dependencies {
        let apiService: APIService
        let doh: DoHInterface
        let downloadService: DownloadService
        let attachmentCacheFolder: URL

        init(
            apiService: APIService,
            doh: DoHInterface = BackendConfiguration.shared.doh,
            downloadService: DownloadService = DownloadService.shared,
            attachmentCacheFolder: URL = FileManager.default.attachmentDirectory
        ) {
            self.apiService = apiService
            self.doh = doh
            self.downloadService = downloadService
            self.attachmentCacheFolder = attachmentCacheFolder
        }
    }
}

struct AttachmentFile {
    let attachmentId: AttachmentID
    /// Path to the local file where the attachment can be found
    let fileUrl: URL
    let data: Data
}
