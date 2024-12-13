// Copyright (c) 2024 Proton Technologies AG
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

import proton_app_uniffi

final class MockDraft: DraftProtocol {
    var mockSender: String = .empty
    var mockSubject: String = .empty
    var mockToRecipients: [String] = []
    var mockCcRecipients: [String] = []
    var mockBccRecipients: [String] = []

    func attachments() -> [AttachmentMetadata] {
        []
    }

    func bccRecipients() -> [String] {
        mockBccRecipients
    }

    func body() -> String {
        .empty
    }

    func ccRecipients() -> [String] {
        mockCcRecipients
    }

    func mimeType() -> MimeType {
        .textHtml
    }

    func save() async -> VoidDraftResult { .ok }

    func send() async -> VoidDraftResult { .ok }

    func sender() -> String {
        mockSender
    }

    func setBccRecipients(recipients: [String]) {}

    func setBody(body: String) {}

    func setCcRecipients(recipients: [String]) {}

    func setSubject(subject: String) {}

    func setToRecipients(recipients: [String]) {}

    func subject() -> String {
        mockSubject
    }

    func toRecipients() -> [String] {
        mockToRecipients
    }
}

extension DraftProtocol where Self == MockDraft {
    static var emptyMock: MockDraft { .init() }
}
