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

import Foundation
import InboxCore
import WebKit

final class BodyWebViewInterface: NSObject {

    enum Event {
        case onContentHeightChange(height: CGFloat)
        case onEditorFocus
        case onEditorChange
        case onCursorPositionChange(position: CGPoint)
    }

    let webView: WKWebView
    var onEvent: ((Event) -> Void)?

    private let htmlDocument: BodyHtmlDocument

    init(webView: WKWebView) {
        self.webView = webView
        self.htmlDocument = BodyHtmlDocument()
        super.init()
        setUpCallbacks()
    }

    private func setUpCallbacks() {
        BodyHtmlDocument.JSEventHandler.allCases.forEach { eventHandler in
            webView.configuration.userContentController.add(self, name: eventHandler.rawValue)
        }
    }

    func loadMessageBody(_ body: String) {
        let html = htmlDocument.html(withTextEditorContent: body)
        webView.loadHTMLString(html, baseURL: nil)
    }

    @MainActor
    func setFocus() async {
        await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(BodyHtmlDocument.JSFunction.setFocus.callFunction) { _, error in
                if let error { AppLogger.log(error: error, category: .composer) }
                continuation.resume()
            }
        }
    }

    @MainActor
    func readMesasgeBody() async -> String? {
        await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(BodyHtmlDocument.JSFunction.getHtmlContent.callFunction) { result, error in
                if let error { AppLogger.log(error: error, category: .composer) }
                guard let html = result as? String else {
                    return continuation.resume(returning: nil)
                }
                continuation.resume(returning: html)
            }
        }
    }
}

extension BodyWebViewInterface: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let userInfo = message.body as! [String: Any]
        let messageHandler = userInfo["messageHandler"] as! String
        let jsEventHandler = BodyHtmlDocument.JSEventHandler(rawValue: messageHandler)!

        switch jsEventHandler.event {
        case .onContentHeightChange:
            let newHeight = userInfo[BodyHtmlDocument.EventAttributeKey.height] as! CGFloat
            onEvent?(.onContentHeightChange(height: newHeight))
        case .onEditorChange:
            onEvent?(.onEditorChange)
        case .onEditorFocus:
            onEvent?(.onEditorFocus)
        case .onCursorPositionChange:
            let positionDict = userInfo[BodyHtmlDocument.EventAttributeKey.cursorPosition] as? [String: CGFloat] ?? [:]
            guard let position = readCursorPosition(from: positionDict) else { return }
            onEvent?(.onCursorPositionChange(position: position))
        }
    }

    private func readCursorPosition(from dict: [String: CGFloat]) -> CGPoint? {
        guard
            let x = dict[BodyHtmlDocument.EventAttributeKey.cursorPositionX],
            let y = dict[BodyHtmlDocument.EventAttributeKey.cursorPositionY]
        else {
            return nil
        }
        return CGPoint(x: x, y: y)
    }
}
