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
import PhotosUI
import SwiftUI

struct PhotosPickerItemHandler  {
    let fileManager = FileManager.default

    func saveToFile(items: [PhotosPickerItemTransferable], destinationFolder: URL) async -> (files: [URL], atLeastOneFailed: Bool) {
        var result = [URL]()
        var atLeastOneFailed: Bool = false
        for item in items {
            do {
                let itemFile = try await saveToFile(item: item, destinationFolder: destinationFolder)
                result.append(itemFile)
            } catch {
                AppLogger.log(error: error, category: .composer)
                atLeastOneFailed = true
            }
        }
        return (result, atLeastOneFailed)
    }

    private func saveToFile(item: PhotosPickerItemTransferable, destinationFolder: URL) async throws -> URL {
        guard let tempFile = try await item.loadTransferable(type: PhotosItemFile.self) else {
            throw PhotosPickerItemHandlerError.loadTransferableFailed
        }
        do {
            let newUrl = try fileManager.moveToUniqueURL(file: tempFile.url, to: destinationFolder)
            try? fileManager.deleteContainingFolder(for: tempFile.url)
            return newUrl
        } catch {
            AppLogger.log(error: error)
            try? fileManager.deleteContainingFolder(for: tempFile.url)
            throw error
        }
    }
}

enum PhotosPickerItemHandlerError: Error {
    case loadTransferableFailed
}

protocol PhotosPickerItemTransferable {
    func loadTransferable<T>(type: T.Type) async throws -> T? where T: Transferable
}

extension PhotosPickerItem: PhotosPickerItemTransferable {}
