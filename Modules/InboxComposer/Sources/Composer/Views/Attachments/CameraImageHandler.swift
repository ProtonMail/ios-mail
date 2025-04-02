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
    let unexpectedError = DraftAttachmentError.other(.unexpected(.fileSystem))

    func addImage(to draft: AppDraftProtocol, image: UIImage, onError: (DraftAttachmentError) -> Void) async {
        let uploadFolder: URL = URL(fileURLWithPath: draft.attachmentList().attachmentUploadDirectory())
        do {
            try fileManager.createDirectory(at: uploadFolder, withIntermediateDirectories: true)
            let destinationFile = uploadFolder
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(UTType.jpeg.preferredFilenameExtension ?? "jpg")
            let imageData = image.jpegData(compressionQuality: JPEG.compressionQuality)
            try imageData?.write(to: destinationFile)
            // FIXME: Add as inline image when supported by SDK
            let result = await draft.attachmentList().add(path: destinationFile.path)
            if case .error(let error) = result {
                onError(error)
            }
        } catch {
            AppLogger.log(error: error, category: .composer)
            onError(unexpectedError)
        }
    }
}
