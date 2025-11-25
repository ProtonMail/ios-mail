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
    struct HTML: Equatable, Sendable {
        let rawBody: String
        let options: TransformOpts
        let imagePolicy: ImagePolicy
    }

    let rsvpServiceProvider: RsvpEventServiceProvider?
    let newsletterService: UnsubscribeNewsletter
    let banners: [MessageBanner]
    let html: HTML
}

struct MessageBodyProvider {
    enum Result: Sendable {
        case success(MessageBody, UniversalSchemeHandler)
        case error(Error)
        case noConnectionError
    }

    private let _messageBody: @Sendable (_ messageID: ID) async -> GetMessageBodyResult

    init(mailbox: Mailbox, wrapper: RustMessageBodyWrapper) {
        _messageBody = { messageID in await wrapper.messageBody(mailbox, messageID) }
    }

    func messageBody(forMessageID messageID: ID, with options: TransformOpts, imagePolicy: ImagePolicy) async -> Result {
        do {
            let decryptedMessage = try await _messageBody(messageID).get()
            let rsvpServiceProvider = await decryptedMessage.identifyRsvp()
            let decryptedBody = try await decryptedMessage.body(opts: options).get()

            let html = MessageBody.HTML(
                rawBody: decryptedBody.body,
                options: decryptedBody.transformOpts,
                imagePolicy: imagePolicy
            )

            let body = MessageBody(
                rsvpServiceProvider: rsvpServiceProvider,
                newsletterService: decryptedMessage,
                banners: decryptedBody.bodyBanners,
                html: html
            )

            let schemeHandler = await UniversalSchemeHandler(imageProxy: decryptedMessage, imagePolicy: imagePolicy)
            return .success(body, schemeHandler)
        } catch ActionError.other(.network) {
            return .noConnectionError
        } catch {
            return .error(error)
        }
    }
}
