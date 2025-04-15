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
import Testing
import UIKit
import UniformTypeIdentifiers

@testable import InboxComposer
@testable import TestableShareExtension

final class DraftPrecomposerTests {
    private let sut = DraftPrecomposer.self
    private let draft = MockDraft()
    private let fileManager = FileManager.default
    private let testDir: URL
    private let attachmentSourceDir: URL
    private let attachmentUploadDir: URL

    init() throws {
        testDir = fileManager.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        attachmentSourceDir = testDir.appending(path: "attachment_source", directoryHint: .isDirectory)
        attachmentUploadDir = testDir.appending(path: "attachment_upload", directoryHint: .isDirectory)

        for dir in [attachmentSourceDir, attachmentUploadDir] {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        draft.mockAttachmentList.attachmentUploadDirectoryURL = attachmentUploadDir
    }

    deinit {
        try! fileManager.removeItem(at: testDir)
    }

    @Test
    func testPopulatingDraftWithoutAttachments() async throws {
        let sharedContent = SharedContent(
            subject: "A subject",
            body: "Some body",
            attachments: []
        )

        try await sut.populate(draft: draft, with: sharedContent)

        #expect(draft.subject() == "A subject")
        #expect(draft.body() == "Some body")
        #expect(draft.mockAttachmentList.capturedAddCalls.count == 0)
    }

    @Test
    func testInsertsInlineAttachmentReferencesInBody() async throws {
        let sourceURLs = (0..<3).map { index in
            attachmentSourceDir.appending(path: "image-\(index).png")
        }

        let sharedContent = SharedContent(
            subject: nil,
            body: "Some body",
            attachments: try TestDataFactory.stubImages(in: sourceURLs)
        )

        try await sut.populate(draft: draft, with: sharedContent)

        let expectedBody =
            #"Some body<div><img src="cid:12345" style="max-width: 100%;"></div><br><div><img src="cid:12345" style="max-width: 100%;"></div><br><div><img src="cid:12345" style="max-width: 100%;"></div><br>"#
        #expect(draft.body() == expectedBody)

        let expectedAttachmentPaths = sourceURLs.map {
            attachmentUploadDir.appending(path: $0.lastPathComponent).path()
        }

        #expect(Set(draft.mockAttachmentList.capturedAddInlineCalls.map(\.path)) == Set(expectedAttachmentPaths))
    }

    @Test
    func testMovesNonInlineAttachmentsToUploadDirectoryBeforeAdding() async throws {
        let sourceURLs = (0..<3).map { index in
            attachmentSourceDir.appending(path: "data-\(index).txt")
        }

        let sharedContent = SharedContent(
            subject: nil,
            body: nil,
            attachments: try TestDataFactory.stubShortLivedData(in: sourceURLs)
        )

        try await sut.populate(draft: draft, with: sharedContent)

        let expectedAttachmentPaths = sourceURLs.map {
            attachmentUploadDir.appending(path: $0.lastPathComponent).path()
        }

        #expect(Set(draft.mockAttachmentList.capturedAddCalls.map(\.path)) == Set(expectedAttachmentPaths))

        for path in expectedAttachmentPaths {
            #expect(FileManager.default.fileExists(atPath: path))
        }
    }
}
