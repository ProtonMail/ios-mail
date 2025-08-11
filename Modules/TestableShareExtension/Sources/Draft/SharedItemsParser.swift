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
        guard let extensionItem = extensionItems.first, let attachments = extensionItem.attachments else {
            return .init(subject: nil, body: nil, attachments: [])
        }

        switch sharedContentPattern(recognizedIn: attachments) {
        case .browserPage:
            let link = try await attachments.first { $0.registeredContentTypes == [.url] }!.loadString()
            let body = "<a href=\"\(link)\">\(link)</a>"
            return .init(subject: extensionItem.attributedContentText?.string, body: body, attachments: [])
        case .selectedText:
            return .init(subject: nil, body: extensionItem.attributedContentText?.string, attachments: [])
        case .none:
            return .init(subject: nil, body: nil, attachments: attachments)
        }
    }

    private static func sharedContentPattern(recognizedIn attachments: [NSItemProvider]) -> SharedContentPattern? {
        let registeredContentTypes = Set(attachments.flatMap(\.registeredContentTypes))

        return SharedContentPattern.allCases.first { pattern in
            pattern.knownSetsOfRegisteredTypes.contains(registeredContentTypes)
        }
    }
}

private enum SharedContentPattern: CaseIterable {
    case browserPage
    case selectedText

    var knownSetsOfRegisteredTypes: [Set<UTType>] {
        switch self {
        case .browserPage:
            [
                [.url],
                [.plainText, .url],
            ]
        case .selectedText:
            [
                [.plainText]
            ]
        }
    }
}
