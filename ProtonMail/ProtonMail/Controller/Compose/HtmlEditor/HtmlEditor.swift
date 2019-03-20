//
//  HtmlEditor.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import PromiseKit

/// workaround for accessoryView
fileprivate final class InputAccessoryHackHelper: NSObject {
    @objc var inputAccessoryView: AnyObject? { return nil }
}

protocol HtmlEditorDelegate : AnyObject {
    func ContentLoaded()
}

/// Html editor
class HtmlEditor: UIView, WKUIDelegate, UIGestureRecognizerDelegate {
    
    enum Exception: Error {
        case castError
        case resEmpty
        case jsError(Error)
    }
    
    //
    private var isEditorLoaded: Bool = false
    private var contentHTML: WebContents = WebContents(body: "", remoteContentMode: .lockdown)
    private var contentHeight : CGFloat = 0
    
    //
    private var webView: WKWebView
    
    //
    private weak var headerView: UIView?
    private var bottomOffsetConstraint: NSLayoutConstraint?
    
    //
    weak var delegate : HtmlEditorDelegate?
    //
    func responderCheck() -> Bool {
        for v in self.webView.scrollView.subviews {
            if v == self.headerView {
                continue
            }
            if v.isFirstResponder {
                return true
            }
        }
        return false
    }
    
    deinit {
        // without this line iOS 9 crashes trying to retain HtmlEditor too many times
        self.webView.scrollView.delegate = nil
    }
    
    // MARK: Initialization
    override init(frame: CGRect) {
        let webConfiguration = WKWebViewConfiguration()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        webConfiguration.preferences = preferences
        self.webView = WKWebView(frame: .zero, configuration: webConfiguration)
        super.init(frame: frame)
        self.setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        let webConfiguration = WKWebViewConfiguration()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        webConfiguration.preferences = preferences
        self.webView = WKWebView(frame:  .zero, configuration: webConfiguration)
        super.init(coder: aDecoder)!
        self.setup()
    }
    func update(footer offset : CGFloat) {
        self.bottomOffsetConstraint?.constant = -offset
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    var keyboardHeight : CGFloat = 0.0
    func update(kbHeight height: CGFloat) {
        self.keyboardHeight = height
    }
    
    private func setup() {
        self.addSubview(webView)
        self.backgroundColor = .white
        self.webView.backgroundColor = .white
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        self.webView.frame = self.frame
        self.webView.scrollView.delegate = self
        self.webView.scrollView.keyboardDismissMode = .interactive
        self.webView.scrollView.layer.masksToBounds = false
    
        self.webView.clipsToBounds = false
        self.webView.autoresizesSubviews = true
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.allowsBackForwardNavigationGestures = false   // Disable swiping to navigate
        self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentHeight = self.webView.scrollView.contentSize.height
        
        ///
        self.hidesInputAccessoryView() //after called this. you can't find subview `WKContent`
        
        
        //add constraint
        let bottomConstraint = NSLayoutConstraint(item: self.webView, attribute: .bottom, relatedBy: .equal,
                                                  toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
        self.bottomOffsetConstraint = bottomConstraint
        //I didnt use leadingAnchor becuase we don't want the mergins and I can't remove it.
        self.addConstraints([
            NSLayoutConstraint(item: self.webView, attribute: .top, relatedBy: .equal,
                               toItem: self, attribute: .top, multiplier: 1.0, constant: 0),
            bottomConstraint,
            NSLayoutConstraint(item: self.webView, attribute: .left, relatedBy: .equal,
                               toItem: self, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.webView, attribute: .right, relatedBy: .equal,
                               toItem: self, attribute: .right, multiplier: 1.0, constant: 0)
            ])
        
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
        
        let editor = html.preg_replace_none_regex("<!--ReplaceToSytle-->", replaceto: css)
                         .preg_replace_none_regex("<!--ReplaceToScript-->", replaceto: [js, purifier].joined(separator: "\n"))
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
    
    var isScrollEnabled : Bool {
        get {
            return self.webView.scrollView.isScrollEnabled
        }
        set {
            self.webView.scrollView.isScrollEnabled = newValue
        }
    }

    
    func setHtml(body: WebContents) {
        contentHTML = body
        if isEditorLoaded {
            self.loadContent()
        }
    }
    
    private func loadContent() {
        self.updateHeaderHeight()
        firstly { () -> Promise<Void> in
            self.run(with: "html_editor.setCSP(\"\(self.contentHTML.remoteContentMode.cspRaw)\");")
        }.then { () -> Promise<Void> in
            self.run(with: "html_editor.setHtml('\(self.contentHTML.body)', \(HTMLStringSecureLoader.domPurifyConfiguration));")
        }.then { (_) -> Promise<CGFloat> in
            self.run(with: "document.body.scrollWidth")
        }.then { (width) -> Promise<Void> in
            if width > self.bounds.width {
                return self.run(with: "html_editor.setWidth('\(width)')")
            } else {
                return Promise.value(())
            }
        }.done {_ in
            self.delegate?.ContentLoaded()
        }.catch { (error) in
            PMLog.D("\(error)")
        }
    }
    
    //
    func set(header view: UIView) {
        self.webView.scrollView.addSubview(view)
        self.webView.scrollView.bringSubviewToFront(view)
        self.headerView = view
        self.updateHeaderHeight()
    }
    
    func updateHeaderHeight() {
        guard let header = self.headerView else {
            return
        }
        let height = header.frame.height
        
        if self.isEditorLoaded {
            self.run(with: "html_editor.updateHeaderHeight('\(height)');").done {
            }.catch { (error) in
                PMLog.D("\(error)")
            }
        }
    }
    
    /// update signature, impl will handle the character escape
    ///
    /// - Parameter html: the raw html signatue, don't run escape before here.
    func update(signature html : String) {
        self.run(with: "html_editor.updateSignature('\(html.escaped)', \(HTMLStringSecureLoader.domPurifyConfiguration));").catch { (error) in
            PMLog.D("Error is \(error.localizedDescription)");
        }
    }
    
    /// Update embed image. designed only support images with based64 encoded
    ///
    /// - Parameters:
    ///   - cid: embed image content id
    ///   - blob: based64 encoded. don't need run escape
    func update(embedImage cid : String, encoded blob : String) {
        self.run(with: "html_editor.updateEmbedImage(\"\(cid)\", \"\(blob)\");").catch { (error) in
            PMLog.D("Error is \(error.localizedDescription)");
        }
    }
    
    
    /// remove exsiting embed by cid
    ///
    /// - Parameter cid: the embed image content id
    func remove(embedImage cid : String) {
        self.run(with: "html_editor.removeEmbedImage('\(cid)');").catch { (error) in
            PMLog.D("Error is \(error.localizedDescription)");
        }
    }
    
    func getOrignalCIDs() -> Promise<String> {
        return self.run(with: "html_editor.removeEmbedImage('');")
    }

    func getEditedCIDs() -> Promise<String> {
        return self.run(with: "html_editor.removeEmbedImage('');")
    }
    
}

extension HtmlEditor: UIScrollViewDelegate {
    
    
    private func adjustOffset(_ scrollView: UIScrollView) {
        
        guard let header = headerView else {
            return
        }
        
        let offset = scrollView.contentOffset
        var offsetX = offset.x
        var width = scrollView.frame.width
        if #available(iOS 11.0, *) {
            let inset = self.webView.safeAreaInsets
            let offsetW = inset.left + inset.right
            width = self.bounds.width - offsetW
            offsetX = offsetX + inset.left
        }
        var f = header.frame
        f.origin.x = offsetX
        f.size.width = width
        header.frame = f

        let height : CGFloat = header.frame.height
        if offset.y < -height {
            if !scrollView.isDragging && !scrollView.isDecelerating {
                scrollView.setContentOffset(CGPoint(x: offset.x, y:-height), animated: false)
            }
        }
    }
    
    //keep the offset in the same position
    private func keepLocation(_ scrollView: UIScrollView) {
        guard let header = headerView else {
            return
        }
        // current offset
        let offset = scrollView.contentOffset
        // current header height
        let height = header.frame.height
        
        if offset.y < 0 && offset.y != -height {
            scrollView.setContentOffset(CGPoint(x: offset.x, y:-height), animated: false)
        }
    }
    
    
    /// when content inset changed
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        self.adjustOffset(scrollView)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.adjustOffset(scrollView)
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return true
    }
}

extension HtmlEditor: WKNavigationDelegate {
    
    /// Called when actions are received from JavaScript
    /// - parameter method: String with the name of the method and optional parameters that were passed in
    private func performCommand(_ method: String) {
        if method.hasPrefix("ready") {
            // If loading for the first time, we have to set the content HTML to be displayed
            if !isEditorLoaded {
                isEditorLoaded = true
            }
        } else if method.hasPrefix("cursor/") {
            let value = method.preg_replace_none_regex("cursor/", replaceto: "")
            if let coursorPosition : CGFloat =  NumberFormatter().number(from: value) as? CGFloat {
                self.scrollCaretToVisible(cursorY: coursorPosition)
            }
        }
        
        
        
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !isEditorLoaded {
            isEditorLoaded = true
            self.loadContent()
        }
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url {
            let scheme = "delegate"
            if url.scheme == scheme {
                PMLog.D(url.absoluteString)
                let command = url.absoluteString.preg_replace_none_regex(scheme + "://", replaceto: "")
                self.performCommand(command)
            }
        }
        decisionHandler(.allow)
    }
    
    func scrollCaretToVisible(cursorY: CGFloat) {
        /// keyboard size
        let kbHeight = self.keyboardHeight
        /// current offset
        let offset = webView.scrollView.contentOffset
        let contentSize = webView.frame.size
        let currentCheck = contentSize.height - (kbHeight + 42) + offset.y
        if currentCheck < cursorY {
            let moveOffset = cursorY - currentCheck
            let newOffset = moveOffset + offset.y + 10
            if newOffset > offset.y {
                webView.scrollView.setContentOffset(CGPoint(x: offset.x, y: newOffset ), animated: true)
            }
        }
    }
}
