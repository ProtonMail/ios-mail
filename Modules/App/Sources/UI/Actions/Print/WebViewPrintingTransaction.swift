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
import SwiftUI
import WebKit

@MainActor
final class WebViewPrintingTransaction {
    private let message: Message
    private let webView: WKWebView

    private let a4PaperWidth = 595
    private let printableRectMargin = 18

    init(message: Message, webView: WKWebView) {
        self.message = message
        self.webView = webView
    }

    func perform<Output>(block: (Message, WKWebView) async throws(PrintError) -> Output) async throws(PrintError) -> Output {
        let headerImage = renderHeaderImage(
            subject: message.subject,
            messageDetails: message.toExpandedMessageCellUIModel().messageDetails
        )

        let injectedHeaderUUID = try await inject(headerImage: headerImage, into: webView)

        let blockResult: Result<Output, PrintError>
        do {
            let output = try await block(message, webView)
            blockResult = .success(output)
        } catch {
            blockResult = .failure(error)
        }

        try await removeHeader(identifiedBy: injectedHeaderUUID, from: webView)

        return try blockResult.get()
    }

    private func renderHeaderImage(subject: String, messageDetails: MessageDetailsUIModel) -> UIImage {
        let header = PrintHeaderView(subject: subject, messageDetails: messageDetails)
        let imageRenderer = ImageRenderer(content: header)
        imageRenderer.scale = UIScreen.main.nativeScale
        imageRenderer.proposedSize.width = .init(a4PaperWidth - 2 * printableRectMargin)
        return imageRenderer.uiImage!
    }

    private func inject(headerImage: UIImage, into webView: WKWebView) async throws(PrintError) -> UUID {
        let injectedHeaderUUID = UUID()
        let headerImageData = headerImage.pngData()!.base64EncodedString()
        let injectionScript = #"document.body.insertAdjacentHTML("afterbegin", `<img id="\#(injectedHeaderUUID)" src="data:image/png;base64,\#(headerImageData)"/>`);"#

        do {
            try await webView.evaluateJavaScript(injectionScript)
        } catch {
            throw PrintError.javaScript(error)
        }

        return injectedHeaderUUID
    }

    private func removeHeader(identifiedBy uuid: UUID, from webView: WKWebView) async throws(PrintError) {
        let removalScript = #"document.getElementById('\#(uuid)')?.remove();"#

        do {
            try await webView.evaluateJavaScript(removalScript)
        } catch {
            throw PrintError.javaScript(error)
        }
    }
}
