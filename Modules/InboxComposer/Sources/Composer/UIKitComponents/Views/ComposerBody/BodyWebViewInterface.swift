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
        case onInlineImageRemoved(cid: String)
        case onInlineImageTapped(cid: String)
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
        BodyHtmlDocument.JSEvent.allCases.forEach { eventHandler in
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
                guard let html = (result as? String)?.withoutWhitespace else {
                    return continuation.resume(returning: nil)
                }
                continuation.resume(returning: html)
            }
        }
    }

    @MainActor
    func insertImages(_ contentIds: [String]) async {
        let jsonArray = contentIds.map { "\"\($0)\"" }.joined(separator: ",")
        let function = "\(BodyHtmlDocument.JSFunction.insertImages.rawValue)([" + jsonArray + "]);"

        await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(function) { _, error in
                if let error { AppLogger.log(error: error, category: .composer) }
                continuation.resume()
            }
        }
    }
    
    @MainActor
    func removeImage(containing cid: String) async {
        let function = "\(BodyHtmlDocument.JSFunction.removeImageWithCID.rawValue)('\(cid)');"
        
        await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(function) { _, error in
                if let error { AppLogger.log(error: error, category: .composer) }
                continuation.resume()
            }
        }
    }
}

extension BodyWebViewInterface: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let userInfo = message.body as! [String: Any]
        let messageHandler = userInfo["messageHandler"] as! String
        let jsEvent = BodyHtmlDocument.JSEvent(rawValue: messageHandler)!

        switch jsEvent {
        case .bodyResize:
            let newHeight = userInfo[BodyHtmlDocument.EventAttributeKey.height] as! CGFloat
            onEvent?(.onContentHeightChange(height: newHeight))
        case .editorChanged:
            onEvent?(.onEditorChange)
        case .focus:
            onEvent?(.onEditorFocus)
        case .cursorPositionChanged:
            let positionDict = userInfo[BodyHtmlDocument.EventAttributeKey.cursorPosition] as? [String: CGFloat] ?? [:]
            guard let position = readCursorPosition(from: positionDict) else { return }
            onEvent?(.onCursorPositionChange(position: position))
        case .inlineImageRemoved:
            if let cid = userInfo["cid"] as? String {
                onEvent?(.onInlineImageRemoved(cid: cid))
            }
        case .inlineImageTapped:
            if let cid = userInfo["cid"] as? String {
                onEvent?(.onInlineImageTapped(cid: cid))
            }
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
