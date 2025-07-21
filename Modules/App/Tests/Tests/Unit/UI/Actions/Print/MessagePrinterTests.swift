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
import Testing
import WebKit

@testable import ProtonMail

@MainActor
final class MessagePrinterTests {
    private lazy var sut = MessagePrinter(
        message: { [unowned self] _ in
            await stubbedMessage
        },
        presentPrintInteractionController: { [unowned self] _ in
            presentPrintInteractionControllerCalls += 1
        }
    )

    private let messageID = ID(integerLiteral: 1)
    private var stubbedMessage: Message? = .testData()
    private var presentPrintInteractionControllerCalls = 0

    @Test
    func givenWebViewIsRegisteredAndMessageIsFound_printsItsContent() async throws {
        let webView = WKWebView()
        sut.register(webView: webView, for: messageID)

        try await sut.printMessage(messageID: messageID)

        #expect(presentPrintInteractionControllerCalls == 1)
    }

    @Test
    func givenWebViewIsNotRegistered_throwsError() async throws {
        let receivedError = await #expect(throws: PrintError.self) {
            try await self.sut.printMessage(messageID: self.messageID)
        }

        #expect(receivedError == .webViewNotFound)
    }

    @Test
    func givenWebViewIsRegisteredButMessageIsNotFound_throwsError() async throws {
        let webView = WKWebView()
        sut.register(webView: webView, for: messageID)

        stubbedMessage = nil

        let receivedError = await #expect(throws: PrintError.self) {
            try await self.sut.printMessage(messageID: self.messageID)
        }

        #expect(receivedError == .messageNotFound)
    }

    @Test
    func registeringWebViewsDoesNotStoreStrongReferencesToThem() async throws {
        var strongRef: WKWebView? = .init()
        weak var weakRef: WKWebView? = strongRef

        sut.register(webView: strongRef!, for: messageID)

        strongRef = nil

        // NSMapTable does not eject immediately
        try await Task.sleep(for: .milliseconds(100))

        #expect(weakRef == nil)
    }
}

extension PrintError: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.webViewNotFound, .webViewNotFound), (.messageNotFound, .messageNotFound):
            true
        case (.javaScript(let lhsError), .javaScript(let rhsError)):
            (lhsError as NSError) == (rhsError as NSError)
        case (.uiPrintError(let lhsError), .uiPrintError(let rhsError)):
            (lhsError as NSError) == (rhsError as NSError)
        default:
            false
        }
    }
}
