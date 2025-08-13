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
import proton_app_uniffi
import Testing
import UIKit
import UniformTypeIdentifiers

@testable import InboxComposer
@testable import TestableShareExtension

final class DraftStubWriterTests {
    private let fileManager = FileManager.default
    private let testDir: URL
    private let attachmentSourceDir: URL
    private let attachmentTemporaryDir: URL
    private var receivedDraftStub: IosShareExtDraft?

    private lazy var sut = DraftStubWriter(
        initDraft: { [unowned self] in
            try? fileManager.removeItem(at: attachmentTemporaryDir)
            try fileManager.createDirectory(at: attachmentTemporaryDir, withIntermediateDirectories: true)
            return attachmentTemporaryDir.path()
        },
        saveDraft: { [unowned self] in
            receivedDraftStub = $0
        }
    )

    init() throws {
        testDir = fileManager.temporaryDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        attachmentSourceDir = testDir.appending(path: "attachment_source", directoryHint: .isDirectory)
        attachmentTemporaryDir = testDir.appending(path: "attachment_upload", directoryHint: .isDirectory)

        try fileManager.createDirectory(at: attachmentSourceDir, withIntermediateDirectories: true)
    }

    deinit {
        try! fileManager.removeItem(at: testDir)
    }

    @Test
    func populatingDraftWithoutAttachments() async throws {
        let sharedContent = SharedContent(
            subject: "A subject",
            body: "Some body",
            attachments: []
        )

        try await sut.createDraftStub(basedOn: sharedContent)

        let draftStub = try #require(receivedDraftStub)
        #expect(draftStub.subject == "A subject")
        #expect(draftStub.body == "Some body")
        #expect(draftStub.inlineAttachments == [])
        #expect(draftStub.attachments == [])
    }

    @Test
    func movesNonInlineAttachmentsToTemporaryDirectoryBeforeAdding() async throws {
        let sourceURLs = (0..<3).map { index in
            attachmentSourceDir.appending(path: "data-\(index).txt")
        }

        let sharedContent = SharedContent(
            subject: nil,
            body: nil,
            attachments: try TestDataFactory.stubShortLivedData(in: sourceURLs)
        )

        try await sut.createDraftStub(basedOn: sharedContent)

        let expectedAttachmentPaths = sourceURLs.map {
            attachmentTemporaryDir.appending(path: $0.lastPathComponent).path()
        }

        let draftStub = try #require(receivedDraftStub)
        #expect(Set(draftStub.attachments.map(\.path)) == Set(expectedAttachmentPaths))

        for path in expectedAttachmentPaths {
            #expect(FileManager.default.fileExists(atPath: path))
        }
    }

    @Test
    func movesInlineAttachmentsToTemporaryDirectoryBeforeAdding() async throws {
        let sourceURLs = (0..<3).map { index in
            attachmentSourceDir.appending(path: "image-\(index).png")
        }

        let sharedContent = SharedContent(
            subject: nil,
            body: nil,
            attachments: try TestDataFactory.stubImages(in: sourceURLs)
        )

        try await sut.createDraftStub(basedOn: sharedContent)

        let expectedAttachmentPaths = sourceURLs.map {
            attachmentTemporaryDir.appending(path: $0.lastPathComponent).path()
        }

        let draftStub = try #require(receivedDraftStub)
        #expect(Set(draftStub.inlineAttachments.map(\.path)) == Set(expectedAttachmentPaths))

        for path in expectedAttachmentPaths {
            #expect(FileManager.default.fileExists(atPath: path))
        }
    }

    @Test
    func extractsImagesFromScreenshotPlists() async throws {
        let sourceURLs = (0..<3).map { index in
            attachmentSourceDir.appending(path: "image-\(index).png")
        }

        let sharedContent = SharedContent(
            subject: nil,
            body: nil,
            attachments: try TestDataFactory.stubScreenshots(in: sourceURLs)
        )

        try await sut.createDraftStub(basedOn: sharedContent)

        let expectedAttachmentPaths = sourceURLs.map {
            attachmentTemporaryDir.appending(path: $0.lastPathComponent)
        }

        #expect(expectedAttachmentPaths.count == 3)

        for url in expectedAttachmentPaths {
            let data = try Data(contentsOf: url)
            #expect(UIImage(data: data) != nil)
        }
    }

    @Test
    func handlesAttachmentLoadingFailures() async throws {
        let sharedContent = SharedContent(
            subject: nil,
            body: nil,
            attachments: [TestDataFactory.stubError()]
        )

        await #expect(throws: NSError.self) {
            try await self.sut.createDraftStub(basedOn: sharedContent)
        }

        #expect(receivedDraftStub == nil)
    }
}
