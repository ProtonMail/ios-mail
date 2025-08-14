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

import InboxCore
import Photos
import proton_app_uniffi
import UIKit

struct CameraImageHandler {
    let fileManager = FileManager.default
    let unexpectedError = DraftAttachmentUploadError.other(.unexpected(.fileSystem))

    func addInlineImage(to draft: AppDraftProtocol, image: UIImage) async throws(DraftAttachmentUploadError) -> String {
        do {
            let destinationFile = try copyImageInDestinationFile(image, draft: draft)
            switch await draft.attachmentList().addInline(path: destinationFile.path, filenameOverride: nil) {
            case .ok(let cid):
                return cid
            case .error(let error):
                throw error
            }
        } catch {
            AppLogger.log(error: error, category: .composer)
            throw unexpectedError
        }
    }

    func addRegularAttachment(to draft: AppDraftProtocol, image: UIImage) async throws(DraftAttachmentUploadError) {
        do {
            let destinationFile = try copyImageInDestinationFile(image, draft: draft)
            switch await draft.attachmentList().add(path: destinationFile.path) {
            case .ok:
                break
            case .error(let error):
                throw error
            }
        } catch {
            AppLogger.log(error: error, category: .composer)
            throw unexpectedError
        }
    }

    private func copyImageInDestinationFile(_ image: UIImage, draft: AppDraftProtocol) throws -> URL {
        let uploadFolder: URL = URL(fileURLWithPath: draft.attachmentList().attachmentUploadDirectory())
        try fileManager.createDirectory(at: uploadFolder, withIntermediateDirectories: true)
        let destinationFile = uploadFolder.appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(UTType.jpeg.preferredFilenameExtension ?? "jpg")
        let imageData = image.jpegData(compressionQuality: JPEG.compressionQuality)
        try imageData?.write(to: destinationFile)
        return destinationFile
    }
}
