// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

struct MIMEAttachmentData {
    let data: Data
    let headers: [Header]

    var cid: String? {
        self.headers[.contentID]?.body
    }

    var contentDisposition: Header? {
        self.headers[.contentDisposition]
    }

    init(data: Data, headersString: String) {
        self.data = data

        headers = [Header](string: headersString)
    }

    func encoded(with scheme: String) -> String {
        switch scheme {
        case "base64":
            return data.base64EncodedString()
        default:
            return "\(data)"
        }
    }

    func getFilename() -> String? {
        if let contentDisposition = self.contentDisposition {
            if let name = contentDisposition.keyValues["filename"] {
                return name
            }
        }

        if let contentType = self.headers[.contentType] {
            if let name = contentType.keyValues["name"] {
                return name
            }
        }

        return nil
    }
}
