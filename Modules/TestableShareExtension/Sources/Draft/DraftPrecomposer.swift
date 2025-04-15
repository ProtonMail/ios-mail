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

import InboxComposer
import proton_app_uniffi
import UIKit
import UniformTypeIdentifiers

enum DraftPrecomposer {
    static func populate(draft: AppDraftProtocol, with sharedContent: SharedContent) async throws {
        if let subject = sharedContent.subject {
            try draft.setSubject(subject: subject).get()
        }

        if let inlineImageHTML = try await add(attachments: sharedContent.attachments, to: draft.attachmentList()) {
            try draft.prependToBody(text: inlineImageHTML.content)
        }

        if let sharedBody = sharedContent.body {
            try draft.prependToBody(text: sharedBody)
        }
    }

    private static func add(attachments: [NSItemProvider], to attachmentList: AttachmentListProtocol) async throws -> InlineImageHTML? {
        let uploadFolder: URL = URL(fileURLWithPath: attachmentList.attachmentUploadDirectory())

        var cids: [String] = []

        for attachment in attachments {
            let url = try await saveFileRepresentation(of: attachment, intoDirectory: uploadFolder)
            let path = url.path(percentEncoded: false)

            if attachment.hasImageRepresentation {
                if try url.isScreenshotInPlistFormat() {
                    try await extractImageContent(of: attachment, into: url)
                }

                let cid = try await attachmentList.addInline(path: path, filenameOverride: nil).get()
                cids.append(cid)
            } else {
                try await attachmentList.add(path: path, filenameOverride: nil).get()
            }
        }

        return cids.isEmpty ? nil : InlineImageHTML(cids: cids)
    }

    private static func saveFileRepresentation(of attachment: NSItemProvider, intoDirectory persistentDirectory: URL) async throws -> URL {
        try await attachment.performOnFileRepresentation { shortLivedURL in
            try FileManager.default.moveToUniqueURL(file: shortLivedURL, to: persistentDirectory)
        }
    }

    private static func extractImageContent(of attachment: NSItemProvider, into url: URL) async throws {
        let image = try await attachment.loadItem(forTypeIdentifier: UTType.image.identifier) as? UIImage
        try image?.jpegData(compressionQuality: JPEG.compressionQuality)?.write(to: url)
    }
}

private extension AppDraftProtocol {
    func prependToBody(text: String) throws {
        let currentBody = body()
        try setBody(body: text + currentBody).get()
    }
}

private extension URL {
    func isScreenshotInPlistFormat() throws -> Bool {
        let plistFileSignature = "bplist00".data(using: .ascii)!
        let handle = try FileHandle(forReadingFrom: self)

        defer {
            try? handle.close()
        }

        let fileSignature = try handle.read(upToCount: plistFileSignature.count)
        return fileSignature == plistFileSignature
    }
}
