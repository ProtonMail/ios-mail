//
// Copyright (c) 2025 Proton Technologies AG
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
import UniformTypeIdentifiers

struct SharedContent {
    let subject: String?
    let body: String?
    let attachments: [NSItemProvider]
}

enum SharedItemsParser {
    static func parse(extensionItems: [NSExtensionItem]) async throws -> SharedContent {
        for extensionItem in extensionItems {
            guard let attachments = extensionItem.attachments else { continue }

            let registeredTypeIdentifiers = attachments.flatMap(\.registeredTypeIdentifiers)
            let isSharingSafariPage = registeredTypeIdentifiers == [UTType.url.identifier]
            let isSharingTextFromSelection = registeredTypeIdentifiers == [UTType.plainText.identifier]

            if isSharingSafariPage {
                let link = try await attachments[0].loadString()
                let body = "<a href=\"\(link)\">\(link)</a>"
                return .init(subject: extensionItem.attributedContentText?.string, body: body, attachments: [])
            } else if isSharingTextFromSelection {
                return .init(subject: nil, body: extensionItem.attributedContentText?.string, attachments: [])
            }
        }

        let allAttachments = extensionItems.compactMap(\.attachments).flatMap(\.self)
        return .init(subject: nil, body: nil, attachments: allAttachments)
    }
}
