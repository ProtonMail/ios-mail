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
import InboxCore
import InboxCoreUI
import PhotosUI
import SwiftUI

struct PhotosPickerItemHandler {
    let fileManager = FileManager.default
    let toastStateStore: ToastStateStore

    func addPickerPhotos(to draft: AppDraftProtocol, photos: [PhotosPickerItemTransferable]) async {
        var errorCount = 0
        let uploadFolder: URL = URL(fileURLWithPath: draft.attachmentList().attachmentUploadDirectory())
        for await result in saveToFile(items: photos, destinationFolder: uploadFolder) {
            switch result {
            case .success(let file):
                let result = await draft.attachmentList().add(path: file.path)
                if case .error(let error) = result {
                    presentToast(toast: .error(message: error.localizedDescription))
                    return
                }
            case .failure:
                errorCount += 1
            }
        }
        notifyAttachmentPreparationErrorsIfNeeded(numErrors: errorCount)
    }

    /**
     Generates a new file for each item passed. It does the operation in parallel to optimise performance.
     Returns an asynchronous sequence that publishes a result for each item without waiting for the rest to complete.
     */
    private func saveToFile(items: [PhotosPickerItemTransferable], destinationFolder: URL) -> AsyncStream<Result<URL, Error>> {
        return AsyncStream { continuation in
            Task {
                await withTaskGroup(of: Result<URL, Error>.self) { group in
                    for item in items {
                        group.addTask {
                            do {
                                let itemFile = try await saveToFile(item: item, destinationFolder: destinationFolder)
                                return .success(itemFile)
                            } catch {
                                AppLogger.log(error: error, category: .composer)
                                return .failure(error)
                            }
                        }
                    }

                    for await result in group {
                        continuation.yield(result)
                    }
                    continuation.finish()
                }
            }
        }
    }

    private func saveToFile(item: PhotosPickerItemTransferable, destinationFolder: URL) async throws -> URL {
        guard let tempFile = try await item.loadTransferable(type: PhotosItemFile.self) else {
            throw PhotosPickerItemHandlerError.loadTransferableFailed
        }
        do {
            if UTType(filenameExtension: tempFile.url.pathExtension) == .heic {
                return try saveHeicImage(image: tempFile.url, destinationFolder: destinationFolder)
            } else {
                let newUrl = try fileManager.moveToUniqueURL(file: tempFile.url, to: destinationFolder)
                try? fileManager.deleteContainingFolder(for: tempFile.url)
                return newUrl
            }
        } catch {
            AppLogger.log(error: error, category: .composer)
            try? fileManager.deleteContainingFolder(for: tempFile.url)
            throw error
        }
    }

    private func saveHeicImage(image: URL, destinationFolder: URL) throws -> URL {
        let jpeg = try convertHeictoJpeg(data: try Data(contentsOf: image))
        let finalUrl = fileManager.uniqueFileNameURL(
            in: destinationFolder,
            baseName: image.deletingPathExtension().lastPathComponent,
            fileExtension: "jpg"
        )
        try fileManager.createDirectory(at: finalUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
        try jpeg.write(to: finalUrl)
        return finalUrl
    }

    private func convertHeictoJpeg(data: Data) throws -> Data {
        guard
            let image = UIImage(data: data),
            let data = image.jpegData(compressionQuality: JPEG.compressionQuality)
        else {
            throw PhotosPickerItemHandlerError.failConvertingHeicToJpeg
        }
        return data
    }

    private func notifyAttachmentPreparationErrorsIfNeeded(numErrors: Int) {
        guard numErrors > 0 else { return }
        let message = numErrors == 1
        ? L10n.Attachments.attachmentCouldNotBeAdded.string
        : L10n.Attachments.someAttachmentCouldNotBeAdded.string
        presentToast(toast: .error(message: message))
    }

    private func presentToast(toast: Toast) {
        Dispatcher.dispatchOnMain(.init(block: {
            toastStateStore.present(toast: toast)
        }))
    }
}

enum PhotosPickerItemHandlerError: Error {
    case loadTransferableFailed
    case failConvertingHeicToJpeg
}

protocol PhotosPickerItemTransferable {
    func loadTransferable<T>(type: T.Type) async throws -> T? where T: Transferable
}

extension PhotosPickerItem: PhotosPickerItemTransferable {}
