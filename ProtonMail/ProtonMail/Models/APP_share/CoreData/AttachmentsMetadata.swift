// Copyright (c) 2023 Proton Technologies AG
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

struct AttachmentsMetadata: Codable, Equatable {
    enum AttachmentDisposition: String, Codable {
        case inline
        case attachment
    }

    let id: String
    let name: String
    let size: Int
    let mimeType: String
    let disposition: AttachmentDisposition

    private enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "Name"
        case size = "Size"
        case mimeType = "MIMEType"
        case disposition = "Disposition"
    }
}

extension AttachmentsMetadata {
    static func decodeListOfDictionaries(jsonString: String) throws -> [AttachmentsMetadata] {
        guard !jsonString.isEmpty else {
            return []
        }
        let decoded = try JSONDecoder().decode([AttachmentsMetadata].self, from: Data(jsonString.utf8))
        return decoded
    }

    static func encodeListOfAttachmentsMetadata(attachmentsMetaData: [AttachmentsMetadata]) throws -> String? {
        let data = try JSONEncoder().encode(attachmentsMetaData)
        return String(data: data, encoding: .utf8)
    }
}
