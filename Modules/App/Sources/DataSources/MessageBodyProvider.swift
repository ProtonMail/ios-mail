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

struct MessageBody: Sendable {
    struct HTML: Sendable {
        let rawBody: String
        let options: TransformOpts
        let embeddedImageProvider: EmbeddedImageProvider
    }
    
    let banners: [MessageBanner]
    let html: HTML
}

struct MessageBodyProvider {
    enum Result: Sendable {
        case success(MessageBody)
        case error(Error)
        case noConnectionError
    }

    private let _messageBody: @Sendable (_ messageID: ID) async -> GetMessageBodyResult

    init(mailbox: Mailbox, bodyWrapper: RustMessageBodyWrapper) {
        _messageBody = { messageID in await bodyWrapper.messageBody(mailbox, messageID) }
    }

    func messageBody(forMessageID messageID: ID, with options: TransformOpts?) async -> Result {
        switch await _messageBody(messageID) {
        case .ok(let decryptedMessage):
            let decryptedBody = await decryptedMessage.body(with: options)
            let html = MessageBody.HTML(
                rawBody: decryptedBody.body,
                options: decryptedBody.transformOpts,
                embeddedImageProvider: decryptedMessage
            )
            let body = MessageBody(banners: decryptedBody.bodyBanners, html: html)
            return .success(body)
        case .error(.other(.network)):
            return .noConnectionError
        case .error(let error):
            return .error(error)
        }
    }
}

struct RustMessageBodyWrapper {
    let messageBody: @Sendable (_ mailbox: Mailbox, _ messageID: Id) async -> GetMessageBodyResult
    
    init(messageBody: @escaping @Sendable (Mailbox, Id) async -> GetMessageBodyResult) {
        self.messageBody = messageBody
    }
}

extension RustMessageBodyWrapper {

    static func productionInstance() -> Self {
        .init(messageBody: { mailbox, id in await getMessageBody(mbox: mailbox, id: id) })
    }

}

private extension DecryptedMessage {
    
    func body(with options: TransformOpts?) async -> BodyOutput {
        guard let options else {
            return await bodyWithDefaults()
        }
        
        return await body(opts: options)
    }
    
}
