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
import protocol ProtonCore_Doh.DoHInterface
import protocol ProtonCore_Services.APIService

typealias FetchAttachmentUseCase = NewUseCase<AttachmentFile, FetchAttachment.Params>

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
                            let encodedAttachment = try self.decrypt(fileUrl: localUrl, params: params)
                            let attachmentFile = AttachmentFile(
                                attachmentId: params.attachmentID,
                                fileUrl: localUrl,
                                encoded: encodedAttachment
                            )
                            callback(.success(attachmentFile))
                        } catch {
                            callback(.failure(FetchAttachmentError(attachmentID: params.attachmentID, error: error)))
                        }
                    case .failure(let error):
                        callback(.failure(FetchAttachmentError(attachmentID: params.attachmentID, error: error)))
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

    private func decrypt(fileUrl: URL, params: Params) throws -> String {
        switch params.purpose {
        case .decryptAndEncodeAttachment:
            return try AttachmentDecrypter.decryptAndEncode(
                fileUrl: fileUrl,
                attachmentKeyPacket: params.attachmentKeyPacket,
                userKeys: params.userKeys
            )
        case .decryptAndEncodePublicKey:
            return try AttachmentDecrypter.decryptAndEncodePublicKey(
                fileUrl: fileUrl,
                attachmentKeyPacket: params.attachmentKeyPacket,
                userKeys: params.userKeys
            )
        case .onlyDownload:
            return ""
        }
    }
}

extension FetchAttachment.Params {
    enum Purpose {
        /// The UseCase will return the file decrypted and encoded to base64
        case decryptAndEncodeAttachment
        /// The UseCase will return the file decrypted and encoded to utf8
        case decryptAndEncodePublicKey
        /// The UseCase won't decrypt the downloaded file.
        case onlyDownload
    }
}

extension FetchAttachment {
    struct Params {
        let attachmentID: AttachmentID
        let attachmentKeyPacket: String?
        let purpose: Purpose
        let userKeys: UserKeys
    }

    struct Dependencies {
        let apiService: APIService
        let doh: DoHInterface
        let downloadService: DownloadService
        let attachmentCacheFolder: URL

        init(
            apiService: APIService,
            doh: DoHInterface = DoHMail.default,
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
    /// Content of the attachment encoded for the specified `Purpose`
    let encoded: String
}

struct FetchAttachmentError: LocalizedError {
    let attachmentID: AttachmentID
    let error: Error

    var errorDescription: String? {
        "FetchAttachmentError: \(error as NSError)"
    }
}
