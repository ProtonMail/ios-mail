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
        case onImagePasted(image: Data)
    }

    let webView: WKWebView
    var onEvent: ((Event) -> Void)?

    private let htmlDocument: BodyHtmlDocument
    private lazy var weakScriptMessageHandler: WeakScriptMessageHandler = {
        WeakScriptMessageHandler(target: self)
    }()

    init(webView: WKWebView) {
        self.webView = webView
        self.htmlDocument = BodyHtmlDocument()
        super.init()
        setUpCallbacks()
    }

    private func setUpCallbacks() {
        BodyHtmlDocument.JSEvent.allCases.forEach { eventHandler in
            webView.configuration.userContentController.add(weakScriptMessageHandler, name: eventHandler.rawValue)
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
        let inlineImageHTML = InlineImageHTML(cids: contentIds).content
        let function = "\(BodyHtmlDocument.JSFunction.insertImages.rawValue)('\(inlineImageHTML)');"

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

    func handleScriptMessage(_ message: WKScriptMessage) {
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
        case .imagePasted:
            guard let data = readImageData(from: userInfo) else { return }
            onEvent?(.onImagePasted(image: data))
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

    private func readImageData(from dict: [String: Any]) -> Data? {
        guard
            let imageBase64 = dict[BodyHtmlDocument.EventAttributeKey.imageData] as? String,
            let data = Data(base64Encoded: imageBase64)
        else {
            AppLogger.log(message: "no image data retrieved", category: .composer, isError: true)
            return nil
        }
        return data
    }
}

/// Weak wrapper to break retain cycle between BodyWebViewInterface and WKUserContentController
private class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: BodyWebViewInterface?

    init(target: BodyWebViewInterface) {
        self.target = target
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.handleScriptMessage(message)
    }
}
