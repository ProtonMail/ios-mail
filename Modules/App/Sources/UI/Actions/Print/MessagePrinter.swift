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

import proton_app_uniffi
import WebKit

@MainActor
final class MessagePrinter: PrintActionPerformer {
    typealias FindMessage = (ID) async throws -> Message?
    typealias PresentPrintInteractionController = (WebViewPrintingTransaction) async throws(PrintError) -> Void

    private let message: FindMessage
    private let presentPrintInteractionController: PresentPrintInteractionController

    private let webViews = NSMapTable<MessageID, WKWebView>.strongToWeakObjects()

    convenience init(userSession: @escaping () -> MailUserSession) {
        self.init(
            message: { try await proton_app_uniffi.message(session: userSession(), id: $0).get() },
            presentPrintInteractionController: PrintInteractionControllerPresenter.present
        )
    }

    init(
        message: @escaping FindMessage,
        presentPrintInteractionController: @escaping PresentPrintInteractionController
    ) {
        self.message = message
        self.presentPrintInteractionController = presentPrintInteractionController
    }

    func register(webView: WKWebView, for messageID: ID) {
        let key = MessageID(rawValue: messageID)
        webViews.setObject(webView, forKey: key)
    }

    func printMessage(messageID: ID) async throws {
        let key = MessageID(rawValue: messageID)

        guard let webView = webViews.object(forKey: key) else {
            throw PrintError.webViewNotFound
        }

        guard let message = try await message(messageID) else {
            throw PrintError.messageNotFound
        }

        let transaction = WebViewPrintingTransaction(message: message, webView: webView)
        try await presentPrintInteractionController(transaction)
    }
}

private final class MessageID: Hashable {
    static func == (lhs: MessageID, rhs: MessageID) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    private let rawValue: ID

    init(rawValue: ID) {
        self.rawValue = rawValue
    }

    func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}
