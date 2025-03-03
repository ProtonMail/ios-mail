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

struct FilePickerItemHandler {
    let fileManager = FileManager.default
    let toastStateStore: ToastStateStore

    func addSelectedFiles(to draft: AppDraftProtocol, selectionResult: Result<[URL], any Error>, uploadFolder: URL) async {
        switch selectionResult {
        case .success(let urls):
            var errorCount = 0
            for await result in copyFilePickerItems(files: urls, destinationFolder: uploadFolder) {
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

        case .failure(let failure):
            presentToast(toast: .error(message: failure.localizedDescription))
        }
    }

    private func copyFilePickerItems(files: [URL], destinationFolder: URL) -> AsyncStream<Result<URL, Error>> {
        return AsyncStream { continuation in
            Task {
                await withTaskGroup(of: Result<URL, Error>.self) { group in
                    for file in files {
                        group.addTask {
                            do {
                                let copiedFile = try self.copySecurityScoped(file: file, to: destinationFolder)
                                return .success(copiedFile)
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

    private func copySecurityScoped(file: URL, to folder: URL) throws -> URL {
        let accessing = file.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                file.stopAccessingSecurityScopedResource()
            }
        }
        return try fileManager.copyToUniqueURL(file: file, to: folder)
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
