// Copyright (c) 2022 Proton AG
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

class SecureTemporaryFile {
    private static let secureFilesDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("files")

    let url: URL

    private let fileManager = FileManager.default

    /*
     This directory is unique for this file and will only ever contain one element.
     The reason for having `name` appended to it is to allow for user-friendly file name and extension - useful when
     sharing.
     */
    private let fileSpecificDirectory: URL

    init(data: Data, name: String) {
        fileSpecificDirectory = Self.secureFilesDirectory.appendingPathComponent(UUID().uuidString)
        let escapedName = name.replacingOccurrences(of: "/", with: "%2F")
        url = fileSpecificDirectory.appendingPathComponent(escapedName)

        do {
            try fileManager.createDirectory(at: fileSpecificDirectory, withIntermediateDirectories: true)
            try data.write(to: url, options: .completeFileProtection)
        } catch {
            assertionFailure("\(error)")
        }
    }

    /*
     Use this method on app launch to remove files that have been created but not cleaned up - possibly because of a
     crash.
     */
    static func cleanUpResidualFiles() {
        try? FileManager.default.removeItem(at: secureFilesDirectory)
    }

    deinit {
        do {
            try fileManager.removeItem(at: fileSpecificDirectory)
        } catch {
            if !(error.isCocoaNoSuchFileError && error.underlying.contains(where: { $0.isPosixNoSuchFileError })) {
                assertionFailure("\(error)")
            }
        }
    }
}

private extension Error {
    var isCocoaNoSuchFileError: Bool {
        belongs(to: NSCocoaErrorDomain, code: NSFileNoSuchFileError)
    }

    var isPosixNoSuchFileError: Bool {
        belongs(to: NSPOSIXErrorDomain, code: Int(POSIXErrorCode.ENOENT.rawValue))
    }

    var underlying: [Error] {
        let nsError = self as NSError

        if #available(iOS 14.5, *) {
            return nsError.underlyingErrors
        } else {
            let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error
            return [underlyingError].compactMap { $0 }
        }
    }

    private func belongs(to domain: String, code: Int) -> Bool {
        let nsError = self as NSError
        return nsError.domain == domain && nsError.code == code
    }
}
