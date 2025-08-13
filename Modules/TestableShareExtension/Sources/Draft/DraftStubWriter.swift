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

public final class DraftStubWriter: Sendable {
    typealias InitDraft = @Sendable () throws -> String
    typealias SaveDraft = @Sendable (IosShareExtDraft) throws -> Void

    private let initDraft: InitDraft
    private let saveDraft: SaveDraft

    init(initDraft: @escaping InitDraft, saveDraft: @escaping SaveDraft) {
        self.initDraft = initDraft
        self.saveDraft = saveDraft
    }

    public convenience init() {
        let mailCacheDir = FileManager.default.sharedCacheDirectory.path()

        self.init(
            initDraft: { try iosShareExtInitDraft(mailCacheDir: mailCacheDir).get() },
            saveDraft: { try iosShareExtSaveDraft(mailCacheDir: mailCacheDir, draft: $0).get() }
        )
    }

    public func createDraftStub(basedOn sharedContent: SharedContent) async throws {
        let attachmentDirectory = try initDraft()

        let (inlineAttachments, nonInlineAttachments) = try await segregate(
            attachments: sharedContent.attachments,
            andStoreIn: .init(filePath: attachmentDirectory)
        )

        let draftStub = IosShareExtDraft(
            subject: sharedContent.subject,
            body: sharedContent.body,
            inlineAttachments: inlineAttachments,
            attachments: nonInlineAttachments
        )

        try saveDraft(draftStub)
    }

    private func segregate(
        attachments: [NSItemProvider],
        andStoreIn attachmentDirectory: URL,
    ) async throws -> (inline: [IosShareExtAttachment], nonInline: [IosShareExtAttachment]) {
        var inlineAttachments: [IosShareExtAttachment] = []
        var nonInlineAttachments: [IosShareExtAttachment] = []

        for attachment in attachments {
            let url = try await saveFileRepresentation(of: attachment, intoDirectory: attachmentDirectory)
            let path = url.path(percentEncoded: false)
            let attachmentInfo = IosShareExtAttachment(path: path, name: attachment.suggestedName)

            if attachment.hasImageRepresentation {
                if try url.isScreenshotInPlistFormat() {
                    try await extractImageContent(of: attachment, into: url)
                }

                inlineAttachments.append(attachmentInfo)
            } else {
                nonInlineAttachments.append(attachmentInfo)
            }
        }

        return (inlineAttachments, nonInlineAttachments)
    }

    private func saveFileRepresentation(of attachment: NSItemProvider, intoDirectory persistentDirectory: URL) async throws -> URL {
        try await attachment.performOnFileRepresentation { shortLivedURL in
            try FileManager.default.moveToUniqueURL(file: shortLivedURL, to: persistentDirectory)
        }
    }

    private func extractImageContent(of attachment: NSItemProvider, into url: URL) async throws {
        let image = try await attachment.loadItem(forTypeIdentifier: UTType.image.identifier) as? UIImage
        try image?.jpegData(compressionQuality: JPEG.compressionQuality)?.write(to: url)
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
