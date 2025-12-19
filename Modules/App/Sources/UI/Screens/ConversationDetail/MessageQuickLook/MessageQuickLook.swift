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
import proton_app_uniffi

@MainActor
@Observable
final class MessageQuickLook {
    typealias RawMessageContent = (Mailbox, ID) async throws -> RawMessageContentProvider

    private let fileManager: FileManager
    private let rawMessageContent: RawMessageContent

    var shortLivedURL: URL? {
        didSet {
            if let oldValue {
                cleanUp(url: oldValue)
            }
        }
    }

    init(fileManager: FileManager, rawMessageContent: @escaping RawMessageContent) {
        self.fileManager = fileManager
        self.rawMessageContent = rawMessageContent
    }

    convenience init() {
        self.init(fileManager: .default) { try await getMessageBody(mbox: $0, id: $1).get() }
    }

    func present(messageID: ID, mailbox: Mailbox, type: MessageQuickLookType) async throws {
        let content = try await rawMessageContent(mailbox, messageID)
        let relevantContent = relevantPart(of: content, for: type)

        let uniqueFileDirectory = fileManager.quickLookTemporaryDirectory.appending(component: UUID().uuidString)
        let filename = filename(for: type)
        let url = uniqueFileDirectory.appendingPathComponent(filename, conformingTo: .plainText)

        try? fileManager.createDirectory(at: uniqueFileDirectory, withIntermediateDirectories: true)
        try Data(relevantContent.utf8).write(to: url, options: .completeFileProtection)

        shortLivedURL = url
    }

    func dismiss() {
        shortLivedURL = nil
    }

    private func relevantPart(of messageContent: RawMessageContentProvider, for type: MessageQuickLookType) -> String {
        switch type {
        case .body:
            messageContent.rawBody()
        case .headers:
            messageContent.rawHeaders()
        }
    }

    private func filename(for type: MessageQuickLookType) -> String {
        switch type {
        case .body:
            "HTML"
        case .headers:
            "Message headers"
        }
    }

    private func cleanUp(url: URL) {
        do {
            try fileManager.removeItem(at: url)
        } catch {
            AppLogger.log(error: error)
        }
    }
}
