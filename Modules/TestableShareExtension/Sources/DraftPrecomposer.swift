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

import CoreTransferable
import InboxComposer
import InboxCore
import UniformTypeIdentifiers

public enum DraftPrecomposer {
    @MainActor
    public static func populate(draft: AppDraftProtocol, with sharedContent: SharedContent) async throws {
        if let subject = sharedContent.subject {
            try draft.setSubject(subject: subject).get()
        }

        let inlineAttachments = sharedContent.attachments.filter { $0.hasImageRepresentation }
        let nonInlineAttachments = sharedContent.attachments.filter { !$0.hasImageRepresentation }

        if !inlineAttachments.isEmpty {
            try await add(inlineAttachments: inlineAttachments, to: draft)
        }

        if !nonInlineAttachments.isEmpty {
            try await add(nonInlineAttachments: nonInlineAttachments, to: draft)
        }

        if let sharedBody = sharedContent.body {
            try prependToBody(text: sharedBody, in: draft)
        }
    }

    private static func add(inlineAttachments: [NSItemProvider], to draft: AppDraftProtocol) async throws {
        let result = await PhotosPickerItemHandler().addPickerPhotos(to: draft, photos: inlineAttachments)

        for error in result.errors {
            AppLogger.log(error: error, category: .shareExtension)
        }

        let inlineAttachmentSection = result.successfulContentIds.map { cid in
            "<div><img src=\"cid:\(cid)\" style=\"max-width: 100%;\"></div><br>"
        }.joined()
        try prependToBody(text: inlineAttachmentSection, in: draft)
    }

    private static func add(nonInlineAttachments: [NSItemProvider], to draft: AppDraftProtocol) async throws {
        let uploadFolder: URL = URL(fileURLWithPath: draft.attachmentList().attachmentUploadDirectory())

        try await withThrowingTaskGroup { group in
            for nonInlineAttachment in nonInlineAttachments {
                group.addTask {
                    let url = try await nonInlineAttachment.saveFileRepresentation(intoDirectory: uploadFolder)
                    try await draft.attachmentList().add(path: url.path(), filenameOverride: nil).get()
                }
            }

            return try await group.waitForAll()
        }
    }

    private static func prependToBody(text: String, in draft: AppDraftProtocol) throws {
        let currentBody = draft.body()
        try draft.setBody(body: text + currentBody).get()
    }
}

extension NSItemProvider: PhotosPickerItemTransferable {
    public func loadTransferable<T: Transferable>(type: T.Type) async throws -> T? {
        try await withCheckedThrowingContinuation { continuation in
            _ = loadTransferable(type: type) { result in
                continuation.resume(with: result)
            }
        }
    }
}

extension NSItemProvider {
    var hasImageRepresentation: Bool {
        hasItemConformingToTypeIdentifier(UTType.image.identifier)
    }

    func saveFileRepresentation(intoDirectory persistentDirectory: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            _ = loadFileRepresentation(for: .data) { shortLivedURL, _, error in
                continuation.resume(
                    with: .init {
                        guard let shortLivedURL else {
                            throw error!
                        }

                        return try FileManager.default.moveToUniqueURL(file: shortLivedURL, to: persistentDirectory)
                    })
            }
        }
    }
}
