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

import InboxCore
import proton_app_uniffi

enum MessageBodyState {
    case loaded(MessageBody)
    case noConnection
    case error(Error)
}

protocol MessageBodyProviding {
    @MainActor
    func messageBody(for messageId: ID) async -> MessageBodyState
}

struct MessageBody {
    let rawBody: String
    let embeddedImageProvider: EmbeddedImageProvider
}

final class MessageBodyProvider: Sendable, MessageBodyProviding {
    private let mailbox: Mailbox

    init(mailbox: Mailbox) {
        self.mailbox = mailbox
    }

    func messageBody(for messageId: ID) async -> MessageBodyState {
        switch await getMessageBody(mbox: mailbox, id: messageId) {
        case .ok(let decryptedMessage):
            let decryptedBody = await decryptedMessage.bodyWithDefaults()
            return .loaded(.init(rawBody: decryptedBody.body, embeddedImageProvider: decryptedMessage))
        case .error(.other(.network)):
            return .noConnection
        case .error(let error):
            return .error(error)
        }
    }
}

extension DecryptedMessage: EmbeddedImageProvider {}
