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

extension FileManager {

    /**
     Moves the given `file` to `destinationFolder`. If a file with the same name exists, it creates a unique file name using `uniqueFileNameURL(in folder:,baseName:,fileExtension:)`
     */
    func moveToUniqueURL(file: URL, to destinationFolder: URL) throws -> URL {
        guard fileExists(atPath: file.path) else {
            throw NSError(
                domain: "moveToUniqueURL".notLocalized,
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "file can't be moved because it does not exist".notLocalized]
            )
        }
        let uniqueURL = uniqueFileNameURL(
            in: destinationFolder,
            baseName: file.deletingPathExtension().lastPathComponent,
            fileExtension: file.pathExtension
        )

        try createDirectory(at: destinationFolder, withIntermediateDirectories: true)
        try moveItem(at: file, to: uniqueURL)
        return uniqueURL
    }

    /**
     Returns a URL for a unique file name inside `folder`.

     If there already exist a file with the same name, it will append a counter to the file base name.

     For exemple in this pseudo code, calling the function twice with the same parameters:
     ```
     uniqueFileURL(in: "/dest_path", baseName: "my_file", fileExtension: "jpg")
     uniqueFileURL(in: "/dest_path", baseName: "my_file", fileExtension: "jpg")
     ```

     would end up with these files in the destination folder:
     ```
     /dest_path/my_file.jpg
     /dest_path/my_file-1.jpg
     ```
     */
    func uniqueFileNameURL(in folder: URL, baseName: String, fileExtension: String) -> URL {
        var newFileURL = folder.appendingPathComponent("\(baseName).\(fileExtension)")
        var counter = 1

        while fileExists(atPath: newFileURL.path) {
            newFileURL = folder.appendingPathComponent("\(baseName)-\(counter).\(fileExtension)")
            counter += 1
        }
        return newFileURL
    }

    /**
     Deletes the entire folder containing `filURL`
     */
    func deleteContainingFolder(for fileURL: URL) throws {
        let folderURL = fileURL.deletingLastPathComponent()
        if fileExists(atPath: folderURL.path) {
            try removeItem(at: folderURL)
        }
    }
}
