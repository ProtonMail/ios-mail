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

import WebKit
import proton_app_uniffi

@MainActor
final class MessagePrinter {
    typealias FindMessage = (ID) async throws -> Message?
    typealias PresentPrintInteractionController = (WebViewPrintingTransaction) async throws(PrintError) -> Void
    typealias AttachmentsProvider = (_ messageID: ID) async throws -> [AttachmentMetadata]

    private let message: FindMessage
    private let presentPrintInteractionController: PresentPrintInteractionController
    private let attachmentsProvider: AttachmentsProvider

    private let webViews = NSMapTable<NSString, WKWebView>.strongToWeakObjects()

    convenience init(userSession: @escaping () -> MailUserSession, mailbox: @escaping () -> Mailbox) {
        self.init(
            message: { try await proton_app_uniffi.message(session: userSession(), id: $0).get() },
            presentPrintInteractionController: PrintInteractionControllerPresenter.present,
            attachmentsProvider: { messageID in
                try await getMessageBody(mbox: mailbox(), id: messageID).get().attachments()
            }
        )
    }

    init(
        message: @escaping FindMessage,
        presentPrintInteractionController: @escaping PresentPrintInteractionController,
        attachmentsProvider: @escaping AttachmentsProvider
    ) {
        self.message = message
        self.presentPrintInteractionController = presentPrintInteractionController
        self.attachmentsProvider = attachmentsProvider
    }

    func register(webView: WKWebView, for messageID: ID) {
        let key = key(for: messageID)
        webViews.setObject(webView, forKey: key)
    }

    func printMessage(messageID: ID) async throws {
        let key = key(for: messageID)

        guard let webView = webViews.object(forKey: key) else {
            throw PrintError.webViewNotFound
        }

        guard let message = try await message(messageID) else {
            throw PrintError.messageNotFound
        }

        let attachments = try await attachmentsProvider(messageID)

        let transaction = WebViewPrintingTransaction(message: message, attachments: attachments, webView: webView)
        try await presentPrintInteractionController(transaction)
    }

    private func key(for messageID: ID) -> NSString {
        "\(messageID.value)" as NSString
    }
}
