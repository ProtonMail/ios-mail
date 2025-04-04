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
import proton_app_uniffi

struct FilePickerItemHandler {
    static let unexpectedError = DraftAttachmentError.other(.unexpected(.fileSystem))
    let fileManager = FileManager.default

    func addSelectedFiles(
        to draft: AppDraftProtocol,
        selectionResult: Result<[URL], any Error>,
        onErrors: ([DraftAttachmentError]) -> Void
    ) async {
        let uploadFolder: URL = URL(fileURLWithPath: draft.attachmentList().attachmentUploadDirectory())
        switch selectionResult {
        case .success(let urls):
            var allErrors = [DraftAttachmentError]()
            for await result in copyFilePickerItems(files: urls, destinationFolder: uploadFolder) {
                switch result {
                case .success(let file):
                    let result = await draft.attachmentList().add(path: file.path)
                    if case .error(let error) = result {
                        allErrors.append(error)
                    }
                case .failure:
                    allErrors.append(Self.unexpectedError)
                }
            }
            onErrors(allErrors)

        case .failure:
            onErrors([Self.unexpectedError])
        }
    }

    private func copyFilePickerItems(files: [URL], destinationFolder: URL) -> AsyncStream<Result<URL, Error>> {
        return AsyncStream { continuation in
            Task {
                for file in files {
                    do {
                        let copiedFile = try copySecurityScoped(file: file, to: destinationFolder)
                        continuation.yield(.success(copiedFile))
                    } catch {
                        AppLogger.log(error: error, category: .composer)
                        continuation.yield(.failure(error))
                    }
                }
                continuation.finish()
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
}
