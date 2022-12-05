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
import ProtonCore_Services

typealias FetchAttachmentsUseCase = NewUseCase<AttachmentFile, FetchAttachments.Params>

final class FetchAttachments: FetchAttachmentsUseCase {
    private let attachmentCacheFolder: URL = FileManager.default.attachmentDirectory
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    /// Given a list of attachment Ids this method will call the callback block once for each of those attachments
    /// with the specific result for that file.
    override func executionBlock(params: Params, callback: @escaping Callback) {
        let attachmentFiles = params.attachments.map(attachmentFile)

        for attachmentFile in attachmentFiles {
            let sourceUrl = remoteUrl(for: attachmentFile)
            dependencies
                .downloadService
                .download(
                    url: sourceUrl,
                    to: attachmentFile.fileUrl,
                    apiService: dependencies.apiService
                ) { result in
                    switch result {
                    case .success:
                        callback(.success(attachmentFile))
                    case .failure(let error):
                        callback(.failure(FetchAttachmentError(attachmentFile: attachmentFile, error: error)))
                    }
                }
        }
    }

    private func attachmentFile(for attachmentID: AttachmentID) -> AttachmentFile {
        let attachmentId = attachmentID.rawValue
        return AttachmentFile(
            attachmentId: attachmentID,
            fileUrl: attachmentCacheFolder.appendingPathComponent(attachmentId)
        )
    }

    private func remoteUrl(for attachmentFile: AttachmentFile) -> URL {
        let url = dependencies.doh.getCurrentlyUsedHostUrl() + "/attachments/" + attachmentFile.attachmentId.rawValue
        // swiftlint:disable:next force_unwrapping
        return URL(string: url)!
    }
}

extension FetchAttachments {
    struct Params {
        let attachments: [AttachmentID]
    }

    struct Dependencies {
        let apiService: APIService
        let doh: DoHInterface
        let downloadService: DownloadService

        init(
            apiService: APIService,
            doh: DoHInterface = DoHMail.default,
            downloadService: DownloadService = DownloadService.shared
        ) {
            self.apiService = apiService
            self.doh = doh
            self.downloadService = downloadService
        }
    }
}

struct AttachmentFile {
    let attachmentId: AttachmentID
    /// Path to the local file where the attachment can be found
    let fileUrl: URL
}

struct FetchAttachmentError: Error {
    let attachmentFile: AttachmentFile
    let error: Error
}
