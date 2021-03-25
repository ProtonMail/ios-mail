//
//  HtmlEditor.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit
import PromiseKit

/// workaround for accessoryView
fileprivate final class InputAccessoryHackHelper: NSObject {
    @objc var inputAccessoryView: AnyObject? { return nil }
}

protocol HtmlEditorBehaviourDelegate : AnyObject {
    func htmlEditorDidFinishLoadingContent()
    func caretMovedTo(_ offset: CGPoint)
    func addInlineAttachment(_ sid: String, data: Data) -> Promise<Void>
    func removeInlineAttachment(_ sid: String)
}

/// Html editor
class HtmlEditorBehaviour: NSObject {
    
    enum Exception: Error {
        case castError
        case resEmpty
        case jsError(Error)
    }
    
    private enum MessageTopics: String {
        case addImage, removeImage, moveCaret, heightUpdated
    }
    
    //
    private var isEditorLoaded: Bool = false
    private var contentHTML: WebContents = WebContents(body: "", remoteContentMode: .lockdown)
    @objc private(set) dynamic var contentHeight : CGFloat = 0
    
    //
    private weak var webView: WKWebView!
    
    //
    weak var delegate : HtmlEditorBehaviourDelegate?
    //
    func responderCheck() -> Bool {
        for v in self.webView.scrollView.subviews {
            if v.isFirstResponder {
                return true
            }
        }
        return false
    }
    
    // fixes retain cycle: userContentController retains his message handlers
    internal func eject() {
        self.webView?.configuration.userContentController.remove(MessageTopics.addImage)
        self.webView?.configuration.userContentController.remove(MessageTopics.removeImage)
        self.webView?.configuration.userContentController.remove(MessageTopics.moveCaret)
        self.webView?.configuration.userContentController.remove(MessageTopics.heightUpdated)
    }
    
    internal func setup(webView: WKWebView) {
        self.webView = webView
        self.webView.scrollView.keyboardDismissMode = .interactive
        webView.configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        webView.configuration.userContentController.add(self, topic: MessageTopics.addImage)
        webView.configuration.userContentController.add(self, topic: MessageTopics.removeImage)
        webView.configuration.userContentController.add(self, topic: MessageTopics.moveCaret)
        webView.configuration.userContentController.add(self, topic: MessageTopics.heightUpdated)
        
        ///
        self.hidesInputAccessoryView() //after called this. you can't find subview `WKContent`
        
        // Load editor 3 parts
        guard let htmlPath = Bundle.main.path(forResource: "HtmlEditor", ofType: "html"),
            let html = try? String(contentsOfFile: htmlPath) else {
                assert(false, "HtmlEditor.html not present in the bundle")
                return //error
        }
        
        guard let cssPath = Bundle.main.path(forResource:  "HtmlEditor", ofType: "css"),
            let css = try? String(contentsOfFile: cssPath) else {
                assert(false, "HtmlEditor.css not present in the bundle")
                return //error
        }
        
        guard let jsPath = Bundle.main.path(forResource: "HtmlEditor", ofType: "js"),
            let js = try? String(contentsOfFile: jsPath) else {
                assert(false, "HtmlEditor.js not present in the bundle")
                return //error
        }
        
        guard let purifierPath = Bundle.main.path(forResource: "purify.min", ofType: "js"),
            let purifier = try? String(contentsOfFile: purifierPath) else {
                assert(false, "purify.min.js not present in the bundle")
                return // error
        }
        guard let jsQuotesPath = Bundle.main.path(forResource: "QuoteBreaker", ofType: "js"),
            let jsQuotes = try? String(contentsOfFile: jsQuotesPath) else {
                assert(false, "QuoteBreaker.js not present in the bundle")
                return // error
        }
        
        let editor = html.preg_replace_none_regex("<!--ReplaceToSytle-->", replaceto: css)
                         .preg_replace_none_regex("<!--ReplaceToScript-->", replaceto: [jsQuotes, js, purifier].joined(separator: "\n"))
        self.webView.loadHTMLString(editor, baseURL: URL(string: "about:blank"))
    }

    /// try to hide the input accessory from the wkwebview when keyboard appear
    private func hidesInputAccessoryView() {
        guard let target = self.webView.scrollView.subviews.first(where: {
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
            let originalMethod = class_getInstanceMethod(InputAccessoryHackHelper.self,
                                                         #selector(getter: InputAccessoryHackHelper.inputAccessoryView)) else {
            return
        }
        class_addMethod(noInputAccessoryClass.self,
                        #selector(getter: InputAccessoryHackHelper.inputAccessoryView),
                        method_getImplementation(originalMethod),
                        method_getTypeEncoding(originalMethod))
        object_setClass(target, noInputAccessoryClass)
    }

    /// clean website cache for wkwebview. not sure if this still necessary
    internal func cleanCache() {
        let websiteDataTypes = Set<String>([WKWebsiteDataTypeDiskCache,
                                            WKWebsiteDataTypeOfflineWebApplicationCache,
                                            WKWebsiteDataTypeMemoryCache,
                                            WKWebsiteDataTypeLocalStorage,
                                            WKWebsiteDataTypeCookies,
                                            WKWebsiteDataTypeSessionStorage,
                                            WKWebsiteDataTypeIndexedDBDatabases,
                                            WKWebsiteDataTypeWebSQLDatabases])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes,
                                                modifiedSince: date,
                                                completionHandler:{ })
    }
    
    
    private func run<T>(with jsCommand: String) -> Promise<T> {
        return Promise { seal in
            DispatchQueue.main.async {
                self.webView.evaluateJavaScript(jsCommand) { (res, error) in
                    if let err = error {
                        seal.reject(Exception.jsError(err))
                    } else {
                        guard let response = res else {
                            seal.reject(Exception.resEmpty)
                            return
                        }
                        guard let ret = response as? T else {
                            seal.reject(Exception.castError)
                            return
                        }
                        seal.fulfill(ret)
                    }
                }
            }
        }
    }
    
    private func run(with jsCommand: String) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                self.webView.evaluateJavaScript(jsCommand) { (res, error) in
                    if let err = error {
                        seal.reject(Exception.jsError(err))
                    } else {
                        seal.fulfill(())
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
        firstly { () -> Promise<Void> in
            self.run(with: "html_editor.setCSP(\"\(self.contentHTML.remoteContentMode.cspRaw)\");")
        }.then { () -> Promise<Void> in
            self.run(with: "html_editor.setHtml('\(self.contentHTML.bodyForJS)', \(HTMLStringSecureLoader.domPurifyConfiguration));")
        }.then { (_) -> Promise<CGFloat> in
            self.run(with: "document.body.scrollWidth")
        }.then { (width) -> Promise<Void> in
            if width > self.webView.bounds.width {
                return self.run(with: "html_editor.setWidth('\(width)')")
            } else {
                return Promise.value(())
            }
        }.then { _ -> Promise<CGFloat> in
            self.run(with: "html_editor.getContentsHeight()")
        }.done { (height) in
            self.contentHeight = height
            self.delegate?.htmlEditorDidFinishLoadingContent()
        }.catch { (error) in
            PMLog.D("\(error)")
        }
    }
    
    /// update signature, impl will handle the character escape
    ///
    /// - Parameter html: the raw html signatue, don't run escape before here.
    func update(signature html : String) {
        self.run(with: "html_editor.updateSignature('\(html.escaped)', \(HTTPRequestSecureLoader.domPurifyConfiguration));").catch { (error) in
            PMLog.D("Error is \(error.localizedDescription)")
        }
    }
    
    /// Update embed image. designed only support images with based64 encoded
    ///
    /// - Parameters:
    ///   - cid: embed image content id
    ///   - blob: based64 encoded. don't need run escape
    func update(embedImage cid : String, encoded blob : String) {
        
        //Use batch process to add the percent encoding to solve the memory issue
        let escapedBlob: String = blob.batchAddingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        
        self.run(with: "html_editor.updateEncodedEmbedImage(\"\(cid)\", \"\(escapedBlob)\");").catch { (error) in
            PMLog.D("Error is \(error.localizedDescription)")
        }
    }
    
    
    /// remove exsiting embed by cid
    ///
    /// - Parameter cid: the embed image content id
    func remove(embedImage cid : String) {
        self.run(with: "html_editor.removeEmbedImage('\(cid)');").catch { (error) in
            PMLog.D("Error is \(error.localizedDescription)")
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
    
    /// Called when actions are received from JavaScript
    /// - parameter method: String with the name of the method and optional parameters that were passed in
    private func performCommand(_ method: String) {
        if method.hasPrefix("ready") {
            // If loading for the first time, we have to set the content HTML to be displayed
            if !isEditorLoaded {
                isEditorLoaded = true
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !isEditorLoaded {
            isEditorLoaded = true
            self.loadContent()
        }
    }
}

extension HtmlEditorBehaviour: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage)
    {
        guard let userInfo = message.body as? Dictionary<String, Any> else {
            assert(false, "Broken message: not a dictionary")
            return
        }
        
        guard let topicRaw = userInfo["messageHandler"] as? String,
            let messageTopic = MessageTopics(rawValue: topicRaw) else
        {
            assert(false, "Broken message: unknown topic")
            return
        }
        
        switch messageTopic {
        case .addImage:
            guard let path = userInfo["cid"] as? String,
                let base64DataString = userInfo["data"] as? String,
                let base64Data = Data(base64Encoded: base64DataString) else
            {
                assert(false, "Broken message: lack important data")
                return
            }
            self.delegate?.addInlineAttachment(path, data: base64Data).cauterize()
            
        case .heightUpdated:
            guard let newHeight = userInfo["height"] as? Double else {
                assert(false, "Broken message: lack important data")
                return
            }
            self.contentHeight = CGFloat(newHeight)
            
        case .moveCaret:
            guard let coursorPositionX = userInfo["cursorX"] as? Double,
                let coursorPositionY = userInfo["cursorY"] as? Double,
                let newHeight = userInfo["height"] as? Double else
            {
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
            self.delegate?.removeInlineAttachment(path)
        }
    }
}

// syntax sugar
fileprivate extension WKUserContentController {
    func add<T: RawRepresentable>(_ scriptMessageHandler: WKScriptMessageHandler, topic: T) where T.RawValue == String {
        self.add(scriptMessageHandler, name: topic.rawValue)
    }
    func remove<T: RawRepresentable>(_ topic: T) where T.RawValue == String {
        self.removeScriptMessageHandler(forName: topic.rawValue)
    }
}
