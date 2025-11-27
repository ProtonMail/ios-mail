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
import proton_app_uniffi

final class HtmlBodyWebViewInterface: NSObject, HtmlBodyWebViewInterfaceProtocol {
    enum Event {
        case onContentHeightChange(height: CGFloat)
        case onEditorFocus
        case onEditorChange
        case onCursorPositionChange(position: CGPoint)
        case onInlineImageRemoved(cid: String)
        case onInlineImageTapped(cid: String, imageRect: CGRect)
        case onImagePasted(image: Data)
        case onTextPasted(text: String)
    }

    let webView: WKWebView
    private let websiteDataStore: WebsiteDataStoreType
    var onEvent: ((Event) -> Void)?

    private let htmlDocument: HtmlBodyDocument
    private lazy var weakScriptMessageHandler: WeakScriptMessageHandler = {
        WeakScriptMessageHandler(target: self)
    }()

    init(webView: WKWebView, websiteDataStore: WebsiteDataStoreType? = nil) {
        self.webView = webView
        self.websiteDataStore = websiteDataStore ?? WKWebsiteDataStoreAdapter(store: webView.configuration.websiteDataStore)
        self.htmlDocument = HtmlBodyDocument()
        super.init()
        setUpCallbacks()
        setUpHtmlScript()
    }

    private func setUpCallbacks() {
        HtmlBodyDocument.JSEvent.allCases.forEach { eventHandler in
            webView.configuration.userContentController.add(weakScriptMessageHandler, name: eventHandler.rawValue)
        }
    }

    private func setUpHtmlScript() {
        let userScript = WKUserScript(
            source: htmlDocument.script,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        webView.configuration.userContentController.addUserScript(userScript)
    }

    func loadMessageBody(_ body: String, clearImageCacheFirst: Bool) async {
        let html = htmlDocument.html(bodyContent: body)

        if clearImageCacheFirst {
            let cachedImageTypes: Set<String> = [WKWebsiteDataTypeMemoryCache]
            await websiteDataStore.removeData(ofTypes: cachedImageTypes, modifiedSince: .distantPast)
        }
        webView.loadHTMLString(html, baseURL: nil)
        Task { await logHtmlHealthCheck(tag: "loadMessageBody") }
    }

    func setFocus() async {
        await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(HtmlBodyDocument.JSFunction.setFocus.callFunction) { _, error in
                if let error { AppLogger.log(error: error, category: .composer) }
                continuation.resume()
            }
        }
    }

    func readMessageBody() async -> String? {
        await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(HtmlBodyDocument.JSFunction.getHtmlContent.callFunction) { result, error in
                if let error { AppLogger.log(error: error, category: .composer) }
                guard let html = (result as? String)?.withoutWhitespace else {
                    AppLogger.log(message: "readMessageBody returned nil", category: .composer, isError: true)
                    Task { [weak self] in await self?.logHtmlHealthCheck(tag: "readMessageBody") }
                    return continuation.resume(returning: nil)
                }
                continuation.resume(returning: html)
            }
        }
    }

    func insertText(_ text: String) async {
        await insertHtml(text, wrapInQuotes: false)
    }

    func insertImages(_ contentIds: [String]) async {
        let inlineImageHTML = InlineImageHTML(cids: contentIds).content
        await insertHtml(inlineImageHTML, wrapInQuotes: true)
    }

    private func insertHtml(_ html: String, wrapInQuotes: Bool) async {
        let function: String
        if wrapInQuotes {
            function = "\(HtmlBodyDocument.JSFunction.insertHtmlAtCurrentPosition.rawValue)('\(html)');"
        } else {
            function = "\(HtmlBodyDocument.JSFunction.insertHtmlAtCurrentPosition.rawValue)(\(html));"
        }

        await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(function) { _, error in
                if let error { AppLogger.log(error: error, category: .composer) }
                continuation.resume()
            }
        }
    }

    func removeImage(containing cid: String) async {
        let function = "\(HtmlBodyDocument.JSFunction.removeImageWithCID.rawValue)('\(cid)');"

        await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(function) { _, error in
                if let error { AppLogger.log(error: error, category: .composer) }
                continuation.resume()
            }
        }
    }

    /// Checks the correctness of the HTML and JS status.
    func logHtmlHealthCheck(tag: String) async {
        let prefix = "[body health check: \(tag)]"
        AppLogger.log(message: "\(prefix) start...", category: .composer)
        let healthCheck =
            """
            (() => ({
              documentState: document.readyState,
              isHtmlEditorInstantiated: !!window.html_editor,
              isTextboxEditorAccessible: !!document.getElementById('editor'),
              isGetHtmlContentAccessible: typeof window.html_editor.getHtmlContent === 'function'
            }))()
            """
        await withCheckedContinuation { continuation in
            let isContentLoaded = !webView.isLoading && webView.estimatedProgress == 1.0
            webView.evaluateJavaScript(healthCheck) { result, error in
                if let error {
                    let message =
                        isContentLoaded
                        ? "JS error: \(error.localizedDescription)"
                        : "JS failed to evaluate content not loaded"
                    AppLogger.log(message: "\(prefix) \(message)", category: .composer, isError: isContentLoaded)
                    return continuation.resume()
                }
                if let dict = result as? [String: Any] {
                    let sortedDict = dict.keys
                        .sorted()
                        .compactMap { key in
                            guard let value = dict[key] else { return "\"\(key)\": nil" }
                            return "\"\(key)\": \(value)"
                        }
                        .joined(separator: ", ")
                    AppLogger.log(message: "\(prefix) \(sortedDict)", category: .composer)
                } else {
                    AppLogger.log(message: "\(prefix) unexpected result: \(String(describing: result))", category: .composer, isError: true)
                }
                continuation.resume()
            }
        }
    }

    func handleScriptMessage(_ message: WKScriptMessage) {
        let userInfo = message.body as! [String: Any]
        let messageHandler = userInfo["messageHandler"] as! String
        let jsEvent = HtmlBodyDocument.JSEvent(rawValue: messageHandler)!

        switch jsEvent {
        case .bodyResize:
            let newHeight = userInfo[HtmlBodyDocument.EventAttributeKey.height] as! CGFloat
            onEvent?(.onContentHeightChange(height: newHeight))
        case .editorChanged:
            onEvent?(.onEditorChange)
        case .focus:
            onEvent?(.onEditorFocus)
        case .cursorPositionChanged:
            let positionDict = userInfo[HtmlBodyDocument.EventAttributeKey.cursorPosition] as? [String: CGFloat] ?? [:]
            guard let position = readCursorPosition(from: positionDict) else { return }
            onEvent?(.onCursorPositionChange(position: position))
        case .inlineImageRemoved:
            if let cid = userInfo["cid"] as? String {
                onEvent?(.onInlineImageRemoved(cid: cid))
            }
        case .inlineImageTapped:
            if let cid = userInfo["cid"] as? String,
                let x = userInfo["x"] as? CGFloat,
                let y = userInfo["y"] as? CGFloat,
                let width = userInfo["width"] as? CGFloat,
                let height = userInfo["height"] as? CGFloat
            {
                onEvent?(.onInlineImageTapped(cid: cid, imageRect: .init(x: x, y: y, width: width, height: height)))
            }
        case .imagePasted:
            guard let data = readImageData(from: userInfo) else { return }
            onEvent?(.onImagePasted(image: data))
        case .textPasted:
            guard let text = readText(from: userInfo) else { return }
            onEvent?(.onTextPasted(text: text))
        }
    }

    private func readCursorPosition(from dict: [String: CGFloat]) -> CGPoint? {
        guard
            let x = dict[HtmlBodyDocument.EventAttributeKey.cursorPositionX],
            let y = dict[HtmlBodyDocument.EventAttributeKey.cursorPositionY]
        else {
            return nil
        }
        return CGPoint(x: x, y: y)
    }

    private func readImageData(from dict: [String: Any]) -> Data? {
        guard
            let imageBase64 = dict[HtmlBodyDocument.EventAttributeKey.imageData] as? String,
            let data = Data(base64Encoded: imageBase64)
        else {
            AppLogger.log(message: "no image data retrieved", category: .composer, isError: true)
            return nil
        }
        return data
    }

    private func readText(from dict: [String: Any]) -> String? {
        guard let text = dict[HtmlBodyDocument.EventAttributeKey.text] as? String else {
            AppLogger.log(message: "no text retrieved", category: .composer, isError: true)
            return nil
        }
        return text
    }
}

/// Weak wrapper to break retain cycle between BodyWebViewInterface and WKUserContentController
private class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: HtmlBodyWebViewInterface?

    init(target: HtmlBodyWebViewInterface) {
        self.target = target
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.handleScriptMessage(message)
    }
}
