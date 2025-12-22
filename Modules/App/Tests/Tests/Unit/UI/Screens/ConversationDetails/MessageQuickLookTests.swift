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

import Testing

@testable import ProtonMail

final class MessageQuickLookTests {
    private let fileManager = FileManager.default

    @MainActor
    private lazy var sut = MessageQuickLook(fileManager: fileManager) { _, _ in
        RawMessageContentProviderStub()
    }

    deinit {
        try? fileManager.removeItem(at: fileManager.quickLookTemporaryDirectory)
    }

    @MainActor
    @Test
    func presentedContentIsPlacedAtShortLivedURL() async throws {
        try await sut.present(messageID: 0, mailbox: .dummy, type: .body)

        let presentedURL = try #require(sut.shortLivedURL)
        let content = try Data(contentsOf: presentedURL)

        #expect(String(data: content, encoding: .utf8) == "stubbed body")
    }

    @MainActor
    @Test
    func cleansUpTemporaryFileWhenViewIsDismissed() async throws {
        try await sut.present(messageID: 0, mailbox: .dummy, type: .headers)

        let presentedURL = try #require(sut.shortLivedURL)
        sut.dismiss()

        #expect(throws: Error.self) {
            try Data(contentsOf: presentedURL)
        }
    }
}

private struct RawMessageContentProviderStub: RawMessageContentProvider {
    func rawBody() -> String {
        "stubbed body"
    }

    func rawHeaders() -> String {
        "stubbed headers"
    }
}
