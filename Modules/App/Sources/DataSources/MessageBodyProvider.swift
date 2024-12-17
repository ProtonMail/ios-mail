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

protocol MessageBodyProviding {
    @MainActor
    func messageBody(for messageId: ID) async -> MessageBody?
}

struct MessageBody {
    let body: String
    let embeddedImageProvider: EmbeddedImageProvider
}

final class MessageBodyProvider: Sendable, MessageBodyProviding {
    private let mailbox: Mailbox

    init(mailbox: Mailbox) {
        self.mailbox = mailbox
    }

    func messageBody(for messageId: ID) async -> MessageBody? {
        do {
            let decryptedMessage = try await getMessageBody(mbox: mailbox, id: messageId).get()
            let tranformOptions = TransformOpts(blockQuote: .untouched, remoteContent: .default)
            let decryptedBody = try await decryptedMessage.body(opts: tranformOptions).get()

            return .init(body: decryptedBody.body, embeddedImageProvider: decryptedMessage)
        } catch {
            AppLogger.log(error: error, category: .conversationDetail)
            return nil
        }
    }
}
