// Copyright (c) 2024 Proton Technologies AG
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
import class proton_mail_uniffi.Mailbox

protocol AttachmentDataSource: Sendable {

    func attachment(for id: PMLocalAttachmentId) async -> Result<URL, Error>
}

struct AttachmentAPIDataSource: AttachmentDataSource {
    private let mailbox: Mailbox

    init(mailbox: Mailbox) {
        self.mailbox = mailbox
    }

    func attachment(for id: PMLocalAttachmentId) async -> Result<URL, Error> {
        do {
            let result = try await mailbox.loadAttachmentToBuffer(localAttachmentId: id)
            guard let cacheFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                throw AppContextError.cacheDirectoryNotAccessible
            }
            let fileUrl = cacheFolder.appendingPathComponent(result.attachmentMetadata.name)
            try result.content.write(to: fileUrl)
            return .success(fileUrl)
        } catch {
            AppLogger.log(error: error)
            return .failure(error)
        }
    }
}
