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
import proton_app_uniffi

@testable import ProtonMail

@MainActor
final class AttachmentViewLoaderTests {
    private var sut: AttachmentViewLoader!
    private let mockMailbox = MockMailbox()
    private let fileManager = FileManager.default

    // MARK: - load

    @Test
    func load_whenNoError_itCallsUpdateStateAttachmentReady() async {
        let sourceFile = createTestFile(named: "test-attachment.pdf")
        let attachment = createAttachment(dataPath: sourceFile.path())
        mockMailbox.attachmentToReturn = .ok(attachment)

        sut = AttachmentViewLoader(mailbox: mockMailbox)
        await sut.load(attachmentId: .random())

        switch sut.state {
        case .attachmentReady:
            #expect(true)
        default:
            Issue.record("Expected .attachmentReady state but got \(sut.state)")
        }
    }

    @Test
    func load_whenNoError_itCopiesAttachmentToTemporaryFile() async {
        let sourceFile = createTestFile(named: "test-document.pdf")
        let attachment = createAttachment(dataPath: sourceFile.path())
        mockMailbox.attachmentToReturn = .ok(attachment)

        sut = AttachmentViewLoader(mailbox: mockMailbox)
        await sut.load(attachmentId: .random())

        switch sut.state {
        case .attachmentReady(let url):
            #expect(fileManager.fileExists(atPath: url.path))
            #expect(url.lastPathComponent == sourceFile.lastPathComponent)
        default:
            Issue.record("Expected .attachmentReady state but got \(sut.state)")
        }
    }

    @Test
    func load_whenError_itCallsUpdateStateError() async {
        let expectedError = ActionError.other(.network)
        mockMailbox.attachmentToReturn = .error(expectedError)

        sut = AttachmentViewLoader(mailbox: mockMailbox)
        await sut.load(attachmentId: .random())

        switch sut.state {
        case .error(let error):
            #expect(error == expectedError)
        default:
            Issue.record("Expected .error state but got \(sut.state)")
        }
    }

    // MARK: cleanupTemporaryFile

    @Test
    func cleanupTemporaryFile_removesTemporaryFile() async {
        let sourceFile = createTestFile(named: "test-cleanup.pdf")
        let attachment = createAttachment(dataPath: sourceFile.path())
        mockMailbox.attachmentToReturn = .ok(attachment)

        sut = AttachmentViewLoader(mailbox: mockMailbox)
        await sut.load(attachmentId: .random())

        guard case .attachmentReady(let url) = sut.state else {
            Issue.record("Failed to load attachment")
            return
        }

        #expect(fileManager.fileExists(atPath: url.path))

        sut.cleanupTemporaryFile()

        #expect(!fileManager.fileExists(atPath: url.path))
    }

    // MARK: - Helper Methods

    private func createTestFile(named fileName: String, content: String = "test content") -> URL {
        let testSourceDirectory = fileManager.temporaryDirectory.appendingPathComponent("test-sources", isDirectory: true)
        try! fileManager.createDirectory(at: testSourceDirectory, withIntermediateDirectories: true)

        let fileURL = testSourceDirectory.appendingPathComponent("test-source-\(UUID().uuidString)-\(fileName)")
        let data = Data(content.utf8)
        try! data.write(to: fileURL, options: .atomic)

        return fileURL
    }

    private func createAttachment(dataPath: String) -> DecryptedAttachment {
        DecryptedAttachment(
            attachmentMetadata: AttachmentMetadata(
                id: Id.random(),
                disposition: .attachment,
                mimeType: AttachmentMimeType(mime: "application/pdf", category: .pdf),
                name: "test.pdf",
                size: 1024,
                isListable: true
            ),
            dataPath: dataPath
        )
    }
}

// MARK: - Mocks

private final class MockMailbox: MailboxProtocol {
    var attachmentToReturn: MailboxGetAttachmentResult?

    func getAttachment(localAttachmentId: Id) async -> MailboxGetAttachmentResult {
        attachmentToReturn ?? .error(.other(.unexpected(.network)))
    }

    func labelId() -> Id {
        fatalError("Not implemented")
    }

    func recipientDisplayMode() -> MessageRecipientDisplayMode {
        fatalError("Not implemented")
    }

    func unreadCount() async -> MailboxUnreadCountResult {
        fatalError("Not implemented")
    }

    func viewMode() -> ViewMode {
        fatalError("Not implemented")
    }

    func watchUnreadCount(callback: any LiveQueryCallback) async -> MailboxWatchUnreadCountResult {
        fatalError("Not implemented")
    }
}
