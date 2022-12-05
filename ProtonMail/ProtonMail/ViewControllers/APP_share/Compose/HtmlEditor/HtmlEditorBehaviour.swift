//
//  HtmlEditor.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import PromiseKit
import ProtonCore_UIFoundations
import UIKit
import WebKit

/// workaround for accessoryView
private final class InputAccessoryHackHelper: NSObject {
    @objc var inputAccessoryView: AnyObject? { return nil }
}

protocol HtmlEditorBehaviourDelegate: AnyObject {
    func htmlEditorDidFinishLoadingContent()
    func caretMovedTo(_ offset: CGPoint)
    func addInlineAttachment(_ sid: String, data: Data, completion: (() -> Void)?)
    func removeInlineAttachment(_ sid: String, completion: (() -> Void)?)
}

/// Html editor
class HtmlEditorBehaviour: NSObject {
    enum Exception: Error {
        case castError
        case resEmpty
        case selfReleased
        case jsError(Error)
    }

    private enum MessageTopics: String {
        case addImage, removeImage, moveCaret, heightUpdated
    }

    //
    private var isEditorLoaded: Bool = false
    private var contentHTML: WebContents = WebContents(body: "", remoteContentMode: .lockdown)
    @objc private(set) dynamic var contentHeight: CGFloat = 0

    //
    private weak var webView: WKWebView?

    //
    weak var delegate: HtmlEditorBehaviourDelegate?

    // fixes retain cycle: userContentController retains his message handlers
    internal func eject() {
        self.webView?.configuration.userContentController.remove(MessageTopics.addImage)
        self.webView?.configuration.userContentController.remove(MessageTopics.removeImage)
        self.webView?.configuration.userContentController.remove(MessageTopics.moveCaret)
        self.webView?.configuration.userContentController.remove(MessageTopics.heightUpdated)
    }

    internal func setup(webView: WKWebView) {
        self.webView = webView
        webView.scrollView.keyboardDismissMode = .interactive
        webView.configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        webView.configuration.userContentController.add(self, topic: MessageTopics.addImage)
        webView.configuration.userContentController.add(self, topic: MessageTopics.removeImage)
        webView.configuration.userContentController.add(self, topic: MessageTopics.moveCaret)
        webView.configuration.userContentController.add(self, topic: MessageTopics.heightUpdated)

        ///
        self.hidesInputAccessoryView() // after called this. you can't find subview `WKContent`

        guard let editor = htmlToInject() else { return }
        self.webView?.loadHTMLString(editor, baseURL: URL(string: "about:blank"))

        updateFontSize()
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged(_:)),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)

    }

    private func htmlToInject() -> String? {
        // Load editor 3 parts
        do {
            let html = try Bundle.loadResource(named: "HtmlEditor", ofType: "html")
            var css = try Bundle.loadResource(named: "HtmlEditor", ofType: "css")

            let backgroundColor = ColorProvider.BackgroundNorm.toHex()
            let textColor = ColorProvider.TextNorm.toHex()
            let brandColor = ColorProvider.BrandNorm.toHex()
            css = css
                .replacingOccurrences(of: "{{proton-background-color}}", with: backgroundColor)
                .replacingOccurrences(of: "{{proton-text-color}}", with: textColor)
                .replacingOccurrences(of: "{{proton-brand-color}}", with: brandColor)

            let script = try Bundle.loadResource(named: "HtmlEditor", ofType: "js")
            let purifier = try Bundle.loadResource(named: "purify.min", ofType: "js")
            let jsQuotes = try Bundle.loadResource(named: "QuoteBreaker", ofType: "js")

            let fullScript = [jsQuotes, script, purifier].joined(separator: "\n")
            let editor = html.preg_replace_none_regex("<!--ReplaceToSytle-->", replaceto: css)
                .preg_replace_none_regex("<!--ReplaceToScript-->", replaceto: fullScript)
            return editor
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    @objc
    private func preferredContentSizeChanged(_ notification: Notification) {
        updateFontSize()
    }

    private func updateFontSize() {
        let font = UIFont.preferredFont(for: .callout, weight: .regular)
        run(with: "html_editor.update_font_size(\(font.pointSize));").cauterize()
    }

    /// try to hide the input accessory from the wkwebview when keyboard appear
    private func hidesInputAccessoryView() {
        guard let target = self.webView?.scrollView.subviews.first(where: {
            String(describing: type(of: $0)).hasPrefix("WKContent")
        }), let superclass = target.superclass else {
            return
        }

        let noInputAccessoryViewClassName = "\(superclass)_NoInputAccessoryView"
        var newClass: AnyClass? = NSClassFromString(noInputAccessoryViewClassName)

        if newClass == nil,
            let targetClass = object_getClass(target),
            let classNameCString = noInputAccessoryViewClassName.cString(using: .ascii) {

            newClass = objc_allocateClassPair(targetClass, classNameCString, 0)
            if let newClass = newClass {
                objc_registerClassPair(newClass)
            }
        }

        guard let noInputAccessoryClass = newClass,
              let originalMethod = class_getInstanceMethod(
                InputAccessoryHackHelper.self,
                #selector(getter: InputAccessoryHackHelper.inputAccessoryView)) else {
            return
        }
        class_addMethod(noInputAccessoryClass.self,
                        #selector(getter: InputAccessoryHackHelper.inputAccessoryView),
                        method_getImplementation(originalMethod),
                        method_getTypeEncoding(originalMethod))
        object_setClass(target, noInputAccessoryClass)
    }

    private func run<T>(with jsCommand: String) -> Promise<T> {
        evaluate(jsCommand: jsCommand).map { res in
            guard let response = res else {
                throw Exception.resEmpty
            }
            guard let ret = response as? T else {
                throw Exception.castError
            }
            return ret
        }
    }

    private func run(with jsCommand: String) -> Promise<Void> {
        evaluate(jsCommand: jsCommand).asVoid()
    }

    private func evaluate(jsCommand: String) -> Promise<Any?> {
        Promise { [weak self] seal in
            DispatchQueue.main.async {
                guard let webView = self?.webView else {
                    seal.reject(Exception.selfReleased)
                    return
                }

                webView.evaluateJavaScript(jsCommand) { res, error in
                    if let err = error {
                        seal.reject(Exception.jsError(err))
                    } else {
                        seal.fulfill(res)
                    }
                }
            }
        }
    }

    /// get html body
    ///
    /// - Returns: return body promise
    func getHtml() -> Promise<String> {
        return run(with: "html_editor.getHtml();")
    }

    func setHtml(body: WebContents) {
        contentHTML = body
        if isEditorLoaded {
            self.loadContent()
        }
    }

    private func loadContent() {
        guard let webView = webView else {
            return
        }

        firstly { () -> Promise<Void> in
            self.run(with: "html_editor.setCSP(\"\(self.contentHTML.remoteContentMode.cspRaw)\");")
        }.then { () -> Promise<Void> in
            if let css = self.contentHTML.supplementCSS {
                return self.run(with: "html_editor.addSupplementCSS(`\(css)`)")
            } else {
                return Promise()
            }
        }.then { () -> Promise<Void> in
            self.run(with: "html_editor.setHtml('\(self.contentHTML.bodyForJS)', \(DomPurifyConfig.default.value));")
        }.then { _ -> Promise<CGFloat> in
            self.run(with: "document.body.scrollWidth")
        }.then { width -> Promise<Void> in
            if width > webView.bounds.width {
                return self.run(with: "html_editor.setWidth('\(width)')")
            } else {
                return Promise.value(())
            }
        }.then { _ -> Promise<CGFloat> in
            self.run(with: "html_editor.getContentsHeight()")
        }.done { height in
            self.contentHeight = height
            self.delegate?.htmlEditorDidFinishLoadingContent()
            self.updateFontSize()
        }.catch { _ in
        }
    }

    /// update signature, impl will handle the character escape
    ///
    /// - Parameter html: the raw html signatue, don't run escape before here.
    func update(signature html: String) {
        self.run(with: "html_editor.updateSignature('\(html.escaped)', \(DomPurifyConfig.default.value));").catch { _ in
        }
    }

    /// Update embed image. designed only support images with based64 encoded
    ///
    /// - Parameters:
    ///   - cid: embed image content id
    ///   - blob: based64 encoded. don't need run escape
    func update(embedImage cid: String, encoded blob: String) {

        // Use batch process to add the percent encoding to solve the memory issue
        let escapedBlob: String = blob.batchAddingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""

        self.run(with: "html_editor.updateEncodedEmbedImage(\"\(cid)\", \"\(escapedBlob)\");").catch { _ in
        }
    }

    /// remove exsiting embed by cid
    ///
    /// - Parameter cid: the embed image content id
    func remove(embedImage cid: String) {
        self.run(with: "html_editor.removeEmbedImage('\(cid)');").catch { _ in
        }
    }

    func getOrignalCIDs() -> Promise<String> {
        return self.run(with: "html_editor.removeEmbedImage('');")
    }

    func getEditedCIDs() -> Promise<String> {
        return self.run(with: "html_editor.removeEmbedImage('');")
    }

    func removeStyleFromSelection() {
        firstly { () -> Promise<Void> in
            return self.run(with: "html_editor.removeStyleFromSelection();")
        }.then {
            self.run(with: "html_editor.getCaretYPosition();")
        }.done {
            // nothing
        }.catch { _ in
            // nothing
        }
    }
}

extension HtmlEditorBehaviour {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !isEditorLoaded {
            isEditorLoaded = true
            self.loadContent()
        }
    }
}

extension HtmlEditorBehaviour: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let userInfo = message.body as? [String: Any] else {
            assert(false, "Broken message: not a dictionary")
            return
        }

        guard let topicRaw = userInfo["messageHandler"] as? String,
            let messageTopic = MessageTopics(rawValue: topicRaw) else {
            assert(false, "Broken message: unknown topic")
            return
        }

        switch messageTopic {
        case .addImage:
            guard let path = userInfo["cid"] as? String,
                let base64DataString = userInfo["data"] as? String,
                let base64Data = Data(base64Encoded: base64DataString) else {
                assert(false, "Broken message: lack important data")
                return
            }
            self.delegate?.addInlineAttachment(path, data: base64Data, completion: nil)

        case .heightUpdated:
            guard let newHeight = userInfo["height"] as? Double else {
                assert(false, "Broken message: lack important data")
                return
            }
            self.contentHeight = CGFloat(newHeight)

        case .moveCaret:
            guard let coursorPositionX = userInfo["cursorX"] as? Double,
                let coursorPositionY = userInfo["cursorY"] as? Double,
                let newHeight = userInfo["height"] as? Double else {
                assert(false, "Broken message: lack important data")
                return
            }
            self.contentHeight = CGFloat(newHeight)
            self.delegate?.caretMovedTo(CGPoint(x: coursorPositionX, y: coursorPositionY))

        case .removeImage:
            guard let path = userInfo["cid"] as? String else {
                assert(false, "Broken message: lack important data")
                return
            }
            self.delegate?.removeInlineAttachment(path, completion: nil)
        }
    }
}

// syntax sugar
private extension WKUserContentController {
    func add<T: RawRepresentable>(_ scriptMessageHandler: WKScriptMessageHandler, topic: T) where T.RawValue == String {
        self.add(scriptMessageHandler, name: topic.rawValue)
    }
    func remove<T: RawRepresentable>(_ topic: T) where T.RawValue == String {
        self.removeScriptMessageHandler(forName: topic.rawValue)
    }
}
