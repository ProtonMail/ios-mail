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
import InboxCoreUI
import Photos
import UIKit

struct CameraImageHandler {
    let fileManager = FileManager.default
    let toastStateStore: ToastStateStore

    func addImage(to draft: AppDraftProtocol, image: UIImage) async {
        let uploadFolder: URL = URL(fileURLWithPath: draft.attachmentList().attachmentUploadDirectory())
        do {
            try fileManager.createDirectory(at: uploadFolder, withIntermediateDirectories: true)
            let destinationFile = uploadFolder
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(UTType.jpeg.preferredFilenameExtension ?? "jpg")
            let imageData = image.jpegData(compressionQuality: 0.8)
            try imageData?.write(to: destinationFile)
            // FIXME: Add as inline image when supported by SDK
            let result = await draft.attachmentList().add(path: destinationFile.path)
            if case .error(let error) = result {
                presentToast(toast: .error(message: error.localizedDescription))
            }
        } catch {
            AppLogger.log(error: error, category: .composer)
            toastStateStore.present(toast: .error(message: L10n.Attachments.attachmentCouldNotBeAdded.string))
        }
    }

    private func presentToast(toast: Toast) {
        Dispatcher.dispatchOnMain(.init(block: {
            toastStateStore.present(toast: toast)
        }))
    }
}
