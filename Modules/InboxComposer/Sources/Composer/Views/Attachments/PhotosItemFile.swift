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

import CoreTransferable
import Foundation

struct PhotosItemFile {
    let url: URL
}

extension PhotosItemFile: Transferable {
    static var fileManager: FileManager = .default
    static var tempDestinationFolderName: String = "\(Bundle.defaultIdentifier).PhotosItemFileTransferable"

    /**
     Receives the transferred data and stores it in a temporary folder with a unique folder name.
    
     Given that the `Transferable` works with static varibles, we can't pass the desired destination folder without
     risking facing some sort of race condition. To avoid that problem we use a unique folder to export the selected file to.
     */
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(
            contentType: .data,
            exporting: { file in
                SentTransferredFile(file.url)
            },
            importing: { received in
                let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
                let tempFolder =
                    cacheDirectory
                    .appendingPathComponent(tempDestinationFolderName, isDirectory: true)
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                try fileManager.createDirectory(at: tempFolder, withIntermediateDirectories: true)
                let tempFileDestination = tempFolder.appendingPathComponent(received.file.lastPathComponent)

                try fileManager.copyItem(at: received.file, to: tempFileDestination)
                return Self.init(url: tempFileDestination)
            }
        )
    }
}
