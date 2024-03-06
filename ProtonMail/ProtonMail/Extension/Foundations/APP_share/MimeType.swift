//  MimeType.swift
//  Proton Mail - Created on 11/30/16.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import CoreServices
import Foundation
import UniformTypeIdentifiers

extension URL {
    func mimeType() -> String {
        MIMETypeBuilder.mimeType(from: pathExtension)
    }
}

extension String {
    var pathExtension: String {
        (self as NSString).pathExtension
    }

    func mimeType() -> String {
        MIMETypeBuilder.mimeType(from: pathExtension)
    }
}

extension AttachmentConvertible {
    func containsExifMetadata(mimeType: String) -> Bool {
        ["image", "video"].contains { type in
            mimeType.lowercased().contains(type)
        }
    }
}

enum MIMEType: String {
    case ics = "text/calendar"
    /// Google's special one that doesn't have standard newlines/
    case applicationICS = "application/ics"
    case `default` = "application/octet-stream"
    case pgpKeys = "application/pgp-keys"
}

private struct MIMETypeBuilder {
    static func mimeType(from fileExtension: String) -> String {
        let utType = UTType(filenameExtension: fileExtension)
        return utType?.preferredMIMEType ?? MIMEType.default.rawValue
    }
}
