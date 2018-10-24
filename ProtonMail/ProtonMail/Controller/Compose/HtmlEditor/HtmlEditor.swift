//
//  HtmlEditor.swift
//  Proton Technologies AG
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
    //func getHeaderHeight() -> CGFloat
    
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
    private var contentHTML: String = ""
    
    //
    private var webView: WKWebView
    
    //
    private weak var headerView: UIView?
    
    //
    weak var delegate : HtmlEditorDelegate?
    
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
    
    private func setup() {
        self.addSubview(webView)
        // add constrains
        self.backgroundColor = .red
        self.webView.backgroundColor = .green
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
        
        /// 
        self.hidesInputAccessoryView()
        
        //I didnt use leadingAnchor becuase we don't want the mergins and I can't remove it.
        self.addConstraints([
            NSLayoutConstraint(item: self.webView, attribute: .top, relatedBy: .equal,
                               toItem: self, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.webView, attribute: .bottom, relatedBy: .equal,
                               toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.webView, attribute: .left, relatedBy: .equal,
                               toItem: self, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.webView, attribute: .right, relatedBy: .equal,
                               toItem: self, attribute: .right, multiplier: 1.0, constant: 0)
            ])
        
        guard let htmlPath = Bundle.main.path(forResource: "HtmlEditor", ofType: "html"),
            let html = try? String(contentsOfFile: htmlPath) else {
                return //error
        }
        
        guard let cssPath = Bundle.main.path(forResource:  "HtmlEditor", ofType: "css"),
            let css = try? String(contentsOfFile: cssPath) else {
                return //error
        }
        
        guard let jsPath = Bundle.main.path(forResource: "HtmlEditor", ofType: "js"),
            let js = try? String(contentsOfFile: jsPath) else {
                return //error
        }
        
        let editor = html.preg_replace_none_regex("<!--ReplaceToSytle-->", replaceto: css).preg_replace_none_regex("<!--ReplaceToScript-->", replaceto: js)
        //let baseURL = URL(fileURLWithPath: "https://protonmail.com")
        self.webView.loadHTMLString(editor, baseURL: nil)
    }
    
    /// Mark -- internal methods
    
    
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

    
    func setHtml(body: String) {
        contentHTML = body
        if isEditorLoaded {
            self.loadContent()
        }
    }
    
    private func loadContent() {
        firstly { () -> Promise<Void> in
            self.run(with: "html_editor.setHtml('\(contentHTML)');")
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
            //
        }
    }
    
    //
    func set(header view: UIView) {
        self.webView.scrollView.addSubview(view)
        self.headerView = view
        self.updateHeaderHeight()
    }
    
    func updateHeaderHeight() {
        guard let header = self.headerView else {
            return
        }
        let height = header.frame.height
        var insets = self.webView.scrollView.contentInset
        insets.top = height
        self.webView.scrollView.contentInset = insets
        var frame = header.frame;
        frame.origin.y = -insets.top
        header.frame = frame
    }
    
    /// update signature
    ///
    /// - Parameter html: the html signatue, don't need to escape
    func update(signature html : String) {
        self.run(with: "html_editor.updateSignature('\(html.escaped)');").catch { (error) in
            NSLog("Error is \(error.localizedDescription)");
        }
    }
    
    func update(embedImage cid : String, encoded blob : String) {
        self.run(with: "html_editor.updateEmbedImage(\"\(cid)\", \"\(blob.escaped)\");").catch { (error) in
            NSLog("Error is \(error.localizedDescription)");
        }
    }
    
    func remove(embedImage cid : String) {
        self.run(with: "html_editor.removeEmbedImage('\(cid)');").catch { (error) in
            NSLog("Error is \(error.localizedDescription)");
        }
    }
    
    func getOrignalCIDs() -> Promise<String> {
        return self.run(with: "html_editor.removeEmbedImage('');")
    }

    func getEditedCIDs() -> Promise<String> {
        return self.run(with: "html_editor.removeEmbedImage('');")
    }
    
    
//    private func updateOffset() {
//
//        var insets = self.webView.scrollView.contentInset
//        insets.top = 360
//        self.webView.scrollView.contentInset = insets
//        var frame = header.frame;
//        frame.origin.y = -insets.top
//        header.frame = frame
////        var insets = UIEdgeInsets.zero
////        insets.top = self.sub.bounds.height
////        self.webView.scrollView.contentInset = insets
////
//        self.webView.scrollView.contentOffset = CGPoint(x: 0, y: -insets.top ) // self.sub.bounds.size.height)
//    }
    
    //    private func setup() {
    //        backgroundColor = .red
    //
    //        //            webView.frame = bounds
    //        //            webView.delegate = self
    //        //            webView.keyboardDisplayRequiresUserAction = false
    //        //            webView.scalesPageToFit = false
    //        //            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    //        //            webView.dataDetectorTypes = UIDataDetectorTypes()
    //        //            webView.backgroundColor = .white
    //        //
    //        //            webView.scrollView.isScrollEnabled = isScrollEnabled
    //        //            webView.scrollView.bounces = false
    //        //            webView.scrollView.delegate = self
    //        //            webView.scrollView.clipsToBounds = false
    //        //
    //        //            webView.cjw_inputAccessoryView = nil
    //        //
    //        //            self.addSubview(webView)
    //        //
    //        //            if let filePath = Bundle(for: RichEditorView.self).path(forResource: "rich_editor", ofType: "html") {
    //        //                let url = URL(fileURLWithPath: filePath, isDirectory: false)
    //        //                let request = URLRequest(url: url)
    //        //                webView.loadRequest(request)
    //        //            }
    //        //
    //        //            tapRecognizer.addTarget(self, action: #selector(viewWasTapped))
    //        //            tapRecognizer.delegate = self
    //        //            addGestureRecognizer(tapRecognizer)
    //    }
    
    //    // MARK: Public Properties
    //
    //    /// The delegate that will receive callbacks when certain actions are completed.
    //    open weak var delegate: RichEditorDelegate?
    //
    //    /// Input accessory view to display over they keyboard.
    //    /// Defaults to nil
    //    open override var inputAccessoryView: UIView? {
    //        get { return webView.cjw_inputAccessoryView }
    //        set { webView.cjw_inputAccessoryView = newValue }
    //    }
    //
    
    //
    //    /// Whether or not scroll is enabled on the view.
    //    open var isScrollEnabled: Bool = true {
    //        didSet {
    //            webView.scrollView.isScrollEnabled = isScrollEnabled
    //        }
    //    }
    //
    //    /// Whether or not to allow user input in the view.
    //    open var isEditingEnabled: Bool {
    //        get { return isContentEditable }
    //        set { isContentEditable = newValue }
    //    }
    //
    //    /// The content HTML of the text being displayed.
    //    /// Is continually updated as the text is being edited.
    //    open private(set) var contentHTML: String = "" {
    //        didSet {
    //            delegate?.richEditor?(self, contentDidChange: contentHTML)
    //        }
    //    }
    //
    //    /// The internal height of the text being displayed.
    //    /// Is continually being updated as the text is edited.
    //    open private(set) var editorHeight: Int = 0 {
    //        didSet {
    //            delegate?.richEditor?(self, heightDidChange: editorHeight)
    //        }
    //    }
    //
    //    /// The value we hold in order to be able to set the line height before the JS completely loads.
    //    private var innerLineHeight: Int = 28
    //
    //    /// The line height of the editor. Defaults to 28.
    //    open private(set) var lineHeight: Int {
    //        get {
    //            if isEditorLoaded, let lineHeight = Int(runJS("RE.getLineHeight();")) {
    //                return lineHeight
    //            } else {
    //                return innerLineHeight
    //            }
    //        }
    //        set {
    //            innerLineHeight = newValue
    //            runJS("RE.setLineHeight('\(innerLineHeight)px');")
    //        }
    //    }
    //
    //    // MARK: Private Properties
    //
    //    /// Whether or not the editor has finished loading or not yet.
    //    private var isEditorLoaded = false
    //
    //    /// Value that stores whether or not the content should be editable when the editor is loaded.
    //    /// Is basically `isEditingEnabled` before the editor is loaded.
    //    private var editingEnabledVar = true
    //
    //    /// The private internal tap gesture recognizer used to detect taps and focus the editor
    //    private let tapRecognizer = UITapGestureRecognizer()
    //
    //    /// The inner height of the editor div.
    //    /// Fetches it from JS every time, so might be slow!
    //    private var clientHeight: Int {
    //        let heightString = runJS("document.getElementById('editor').clientHeight;")
    //        return Int(heightString) ?? 0
    //    }
    //
    //    // MARK: Initialization
    //
    //    public override init(frame: CGRect) {
    //        webView = UIWebView()
    //        super.init(frame: frame)
    //        setup()
    //    }
    //
    //    required public init?(coder aDecoder: NSCoder) {
    //        webView = UIWebView()
    //        super.init(coder: aDecoder)
    //        setup()
    //    }
    //
    //    private func setup() {
    //        backgroundColor = .red
    //
    //        webView.frame = bounds
    //        webView.delegate = self
    //        webView.keyboardDisplayRequiresUserAction = false
    //        webView.scalesPageToFit = false
    //        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    //        webView.dataDetectorTypes = UIDataDetectorTypes()
    //        webView.backgroundColor = .white
    //
    //        webView.scrollView.isScrollEnabled = isScrollEnabled
    //        webView.scrollView.bounces = false
    //        webView.scrollView.delegate = self
    //        webView.scrollView.clipsToBounds = false
    //
    //        webView.cjw_inputAccessoryView = nil
    //
    //        self.addSubview(webView)
    //
    //        if let filePath = Bundle(for: RichEditorView.self).path(forResource: "rich_editor", ofType: "html") {
    //            let url = URL(fileURLWithPath: filePath, isDirectory: false)
    //            let request = URLRequest(url: url)
    //            webView.loadRequest(request)
    //        }
    //
    //        tapRecognizer.addTarget(self, action: #selector(viewWasTapped))
    //        tapRecognizer.delegate = self
    //        addGestureRecognizer(tapRecognizer)
    //    }
    //
    //    // MARK: - Rich Text Editing
    
    //
    //    /// Text representation of the data that has been input into the editor view, if it has been loaded.
    //    public var text: String {
    //        return runJS("RE.getText()")
    //    }
    //
    //    /// Private variable that holds the placeholder text, so you can set the placeholder before the editor loads.
    //    private var placeholderText: String = ""
    //    /// The placeholder text that should be shown when there is no user input.
    //    open var placeholder: String {
    //        get { return placeholderText }
    //        set {
    //            placeholderText = newValue
    //            runJS("RE.setPlaceholderText('\(newValue.escaped)');")
    //        }
    //    }
    //
    //
    //    /// The href of the current selection, if the current selection's parent is an anchor tag.
    //    /// Will be nil if there is no href, or it is an empty string.
    //    public var selectedHref: String? {
    //        if !hasRangeSelection { return nil }
    //        let href = runJS("RE.getSelectedHref();")
    //        if href == "" {
    //            return nil
    //        } else {
    //            return href
    //        }
    //    }
    //
    //    /// Whether or not the selection has a type specifically of "Range".
    //    public var hasRangeSelection: Bool {
    //        return runJS("RE.rangeSelectionExists();") == "true" ? true : false
    //    }
    //
    //    /// Whether or not the selection has a type specifically of "Range" or "Caret".
    //    public var hasRangeOrCaretSelection: Bool {
    //        return runJS("RE.rangeOrCaretSelectionExists();") == "true" ? true : false
    //    }
    //
    //    // MARK: Methods
    //
    //    public func removeFormat() {
    //        runJS("RE.removeFormat();")
    //    }
    //
    //    public func setFontSize(_ size: Int) {
    //        runJS("RE.setFontSize('\(size)px');")
    //    }
    //
    //    public func setEditorBackgroundColor(_ color: UIColor) {
    //        runJS("RE.setBackgroundColor('\(color.hex)');")
    //    }
    //
    //    public func undo() {
    //        runJS("RE.undo();")
    //    }
    //
    //    public func redo() {
    //        runJS("RE.redo();")
    //    }
    //
    //    public func bold() {
    //        runJS("RE.setBold();")
    //    }
    //
    //    public func italic() {
    //        runJS("RE.setItalic();")
    //    }
    //
    //    // "superscript" is a keyword
    //    public func subscriptText() {
    //        runJS("RE.setSubscript();")
    //    }
    //
    //    public func superscript() {
    //        runJS("RE.setSuperscript();")
    //    }
    //
    //    public func strikethrough() {
    //        runJS("RE.setStrikeThrough();")
    //    }
    //
    //    public func underline() {
    //        runJS("RE.setUnderline();")
    //    }
    //
    //    public func setTextColor(_ color: UIColor) {
    //        runJS("RE.prepareInsert();")
    //        runJS("RE.setTextColor('\(color.hex)');")
    //    }
    //
    //    public func setEditorFontColor(_ color: UIColor) {
    //        runJS("RE.setBaseTextColor('\(color.hex)');")
    //    }
    //
    //    public func setTextBackgroundColor(_ color: UIColor) {
    //        runJS("RE.prepareInsert();")
    //        runJS("RE.setTextBackgroundColor('\(color.hex)');")
    //    }
    //
    //    public func header(_ h: Int) {
    //        runJS("RE.setHeading('\(h)');")
    //    }
    //
    //    public func indent() {
    //        runJS("RE.setIndent();")
    //    }
    //
    //    public func outdent() {
    //        runJS("RE.setOutdent();")
    //    }
    //
    //    public func orderedList() {
    //        runJS("RE.setOrderedList();")
    //    }
    //
    //    public func unorderedList() {
    //        runJS("RE.setUnorderedList();")
    //    }
    //
    //    public func blockquote() {
    //        runJS("RE.setBlockquote()");
    //    }
    //
    //    public func alignLeft() {
    //        runJS("RE.setJustifyLeft();")
    //    }
    //
    //    public func alignCenter() {
    //        runJS("RE.setJustifyCenter();")
    //    }
    //
    //    public func alignRight() {
    //        runJS("RE.setJustifyRight();")
    //    }
    //
    //    public func insertImage(_ url: String, alt: String) {
    //        runJS("RE.prepareInsert();")
    //        runJS("RE.insertImage('\(url.escaped)', '\(alt.escaped)');")
    //    }
    //
    //    public func insertLink(_ href: String, title: String) {
    //        runJS("RE.prepareInsert();")
    //        runJS("RE.insertLink('\(href.escaped)', '\(title.escaped)');")
    //    }
    //
    //    public func focus() {
    //        runJS("RE.focus();")
    //    }
    //
    //    public func focus(at: CGPoint) {
    //        runJS("RE.focusAtPoint(\(at.x), \(at.y));")
    //    }
    //
    //    public func blur() {
    //        runJS("RE.blurFocus()")
    //    }
    
    
    
    
    
    //
    //    // MARK: - Delegate Methods
    //
    //
    //    // MARK: UIScrollViewDelegate
    //
    //    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    //        // We use this to keep the scroll view from changing its offset when the keyboard comes up
    //        if !isScrollEnabled {
    //            scrollView.bounds = webView.bounds
    //        }
    //    }
    //
    //
    //    // MARK: UIWebViewDelegate
    //
    //    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
    //
    //        // Handle pre-defined editor actions
    //        let callbackPrefix = "re-callback://"
    //        if request.url?.absoluteString.hasPrefix(callbackPrefix) == true {
    //
    //            // When we get a callback, we need to fetch the command queue to run the commands
    //            // It comes in as a JSON array of commands that we need to parse
    //            let commands = runJS("RE.getCommandQueue();")
    //
    //            if let data = commands.data(using: .utf8) {
    //
    //                let jsonCommands: [String]
    //                do {
    //                    jsonCommands = try JSONSerialization.jsonObject(with: data) as? [String] ?? []
    //                } catch {
    //                    jsonCommands = []
    //                    NSLog("RichEditorView: Failed to parse JSON Commands")
    //                }
    //
    //                jsonCommands.forEach(performCommand)
    //            }
    //
    //            return false
    //        }
    //
    //        // User is tapping on a link, so we should react accordingly
    //        if navigationType == .linkClicked {
    //            if let
    //                url = request.url,
    //                let shouldInteract = delegate?.richEditor?(self, shouldInteractWith: url)
    //            {
    //                return shouldInteract
    //            }
    //        }
    //
    //        return true
    //    }
    //
    //
    //    // MARK: UIGestureRecognizerDelegate
    //
    //    /// Delegate method for our UITapGestureDelegate.
    //    /// Since the internal web view also has gesture recognizers, we have to make sure that we actually receive our taps.
    //    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    //        return true
    //    }
    //
    //
    //    // MARK: - Private Implementation Details
    //
    //    private var isContentEditable: Bool {
    //        get {
    //            if isEditorLoaded {
    //                let value = runJS("RE.editor.isContentEditable")
    //                editingEnabledVar = Bool(value) ?? false
    //                return editingEnabledVar
    //            }
    //            return editingEnabledVar
    //        }
    //        set {
    //            editingEnabledVar = newValue
    //            if isEditorLoaded {
    //                let value = newValue ? "true" : "false"
    //                runJS("RE.editor.contentEditable = \(value);")
    //            }
    //        }
    //    }
    //
    //    /// The position of the caret relative to the currently shown content.
    //    /// For example, if the cursor is directly at the top of what is visible, it will return 0.
    //    /// This also means that it will be negative if it is above what is currently visible.
    //    /// Can also return 0 if some sort of error occurs between JS and here.
    //    private var relativeCaretYPosition: Int {
    //        let string = runJS("RE.getRelativeCaretYPosition();")
    //        return Int(string) ?? 0
    //    }
    //
    //    private func updateHeight() {
    //        let heightString = runJS("document.getElementById('editor').clientHeight;")
    //        let height = Int(heightString) ?? 0
    //        if editorHeight != height {
    //            editorHeight = height
    //        }
    //    }
    //
    //    /// Scrolls the editor to a position where the caret is visible.
    //    /// Called repeatedly to make sure the caret is always visible when inputting text.
    //    /// Works only if the `lineHeight` of the editor is available.
    //    private func scrollCaretToVisible() {
    //        /*let scrollView = self.webView.scrollView
    //
    //         let contentHeight = clientHeight > 0 ? CGFloat(clientHeight) : scrollView.frame.height
    //         scrollView.contentSize = CGSize(width: scrollView.frame.width, height: contentHeight)
    //
    //         // XXX: Maybe find a better way to get the cursor height
    //         let lineHeight = CGFloat(self.lineHeight)
    //         let cursorHeight = lineHeight - 4
    //         let visiblePosition = CGFloat(relativeCaretYPosition)
    //         var offset: CGPoint?
    //
    //         if visiblePosition + cursorHeight > scrollView.bounds.size.height {
    //         // Visible caret position goes further than our bounds
    //         offset = CGPoint(x: 0, y: (visiblePosition + lineHeight) - scrollView.bounds.height + scrollView.contentOffset.y)
    //
    //         } else if visiblePosition < 0 {
    //         // Visible caret position is above what is currently visible
    //         var amount = scrollView.contentOffset.y + visiblePosition
    //         amount = amount < 0 ? 0 : amount
    //         offset = CGPoint(x: scrollView.contentOffset.x, y: amount)
    //
    //         }
    //
    //         if let offset = offset {
    //         scrollView.setContentOffset(offset, animated: true)
    //         }*/
    //    }
    //
    
    //
    //    // MARK: - Responder Handling
    //
    //    /// Called by the UITapGestureRecognizer when the user taps the view.
    //    /// If we are not already the first responder, focus the editor.
    //    @objc private func viewWasTapped() {
    //        if !webView.containsFirstResponder {
    //            let point = tapRecognizer.location(in: webView)
    //            focus(at: point)
    //        }
    //    }
    //
    //    override open func becomeFirstResponder() -> Bool {
    //        if !webView.containsFirstResponder {
    //            focus()
    //            return true
    //        } else {
    //            return false
    //        }
    //    }
    //
    //    open override func resignFirstResponder() -> Bool {
    //        blur()
    //        return true
    //    }
    
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
            width = UIScreen.main.bounds.width - offsetW
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
//            if !scrollView.isDragging && !scrollView.isDecelerating {
                scrollView.setContentOffset(CGPoint(x: offset.x, y:-height), animated: false)
//            }
        }
    }
    
    
    /// when content inset changed
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        self.adjustOffset(scrollView)
        self.keepLocation(scrollView)
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
                //                html = contentHTML
                //                isContentEditable = editingEnabledVar
                //                placeholder = placeholderText
                //                lineHeight = innerLineHeight
                //                delegate?.richEditorDidLoad?(self)
                //                runJS("document.getElementById('editor').innerHTML='\(escaped(input: contentHTML));'")
                //                runJS("RE.setHtml('\(escaped(input: contentHTML))');")
            }
            //            updateHeight()
        }
        //        else if method.hasPrefix("input") {
        //            scrollCaretToVisible()
        //            let content = runJS("RE.getHtml()")
        //            contentHTML = content
        //            updateHeight()
        //        }
        //        else if method.hasPrefix("updateHeight") {
        //            updateHeight()
        //        }
        //        else if method.hasPrefix("focus") {
        //            delegate?.richEditorTookFocus?(self)
        //        }
        //        else if method.hasPrefix("blur") {
        //            delegate?.richEditorLostFocus?(self)
        //        }
        //        else if method.hasPrefix("action/") {
        //            let content = runJS("RE.getHtml()")
        //            contentHTML = content
        //
        //            // If there are any custom actions being called
        //            // We need to tell the delegate about it
        //            let actionPrefix = "action/"
        //            let range = method.range(of: actionPrefix)!
        //            let action = method.replacingCharacters(in: range, with: "")
        //            delegate?.richEditor?(self, handle: action)
        //        }
    }
    
    //    didFailLoadWithError => didFailNavigation
    //    webViewDidFinishLoad => didFinishNavigation
    //    webViewDidStartLoad => didStartProvisionalNavigation
    //    shouldStartLoadWithRequest => decidePolicyForNavigationAction
    //    About shouldStartLoadWithRequest you can write:
    
    //    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
    //        print("webView:\(webView) decidePolicyForNavigationAction:\(navigationAction) decisionHandler:\(decisionHandler)")
    //
    //        switch navigationAction.navigationType {
    //        case .LinkActivated:
    //            if navigationAction.targetFrame == nil {
    //                self.webView?.loadRequest(navigationAction.request)
    //            }
    //            if let url = navigationAction.request.URL where !url.absoluteString.hasPrefix("http://www.myWebSite.com/example") {
    //                UIApplication.sharedApplication().openURL(url)
    //                print(url.absoluteString)
    //                decisionHandler(.Cancel)
    //                return
    //            }
    //        default:
    //            break
    //        }
    //

    //        decisionHandler(.Allow)
    //    }
    //    And for the didFailLoadWithError:
    //
    //    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation, withError error: NSError) {
    //        print("webView:\(webView) didFailNavigation:\(navigation) withError:\(error)")
    //        let testHTML = NSBundle.mainBundle().pathForResource("back-error-bottom", ofType: "jpg")
    //        let baseUrl = NSURL(fileURLWithPath: testHTML!)
    //
    //        let htmlString:String! = "myErrorinHTML"
    //        self.webView.loadHTMLString(htmlString, baseURL: baseUrl)
    //    }
    //
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("Loaded")
        if !isEditorLoaded {
            isEditorLoaded = true
            self.loadContent()
            
            
//            self.webView.evaluateJavaScript("html_editor.setHtml('\(contentHTML)');") { (res, error) in
//
//                NSLog("Error is \(error)");
//                NSLog("JS result \(res) ");
//                self.webView.evaluateJavaScript("document.body.scrollWidth") { (res, error) in
//                    if let width = res as? CGFloat, width > self.bounds.width {
//                        self.webView.evaluateJavaScript("html_editor.setWidth('\(width)')", completionHandler: { (res, error) in
//                        })
//                    }
//                }
//                if error == nil {
//                    self.delegate?.ContentLoaded()
//                }
//            }
            
            //isContentEditable = editingEnabledVar
            //placeholder = placeholderText
            //lineHeight = innerLineHeight
            //delegate?.richEditorDidLoad?(self)
            //runJS("document.getElementById('editor').innerHTML='\(escaped(input: contentHTML));'")
            //runJS("RE.setHtml('\(escaped(input: contentHTML))');")
        }
    }
    
    
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url {
            print(url.absoluteString)
        }
        decisionHandler(.allow)
        //        return
        //        // Handle pre-defined editor actions
        //        guard let url = navigationAction.request.url else {
        //            return decisionHandler(.allow)
        //        }
        //        print(url.absoluteString)
        //        let callbackPrefix = "re-callback://"
        //        if url.absoluteString.hasPrefix(callbackPrefix) {
        //
        //            // When we get a callback, we need to fetch the command queue to run the commands
        //            // It comes in as a JSON array of commands that we need to parse
        //            let commands = runJS("RE.getCommandQueue();")
        //            if let data = commands.data(using: .utf8) {
        //
        //                let jsonCommands: [String]
        //                do {
        //                    jsonCommands = try JSONSerialization.jsonObject(with: data) as? [String] ?? []
        //                } catch {
        //                    jsonCommands = []
        //                    NSLog("RichEditorView: Failed to parse JSON Commands")
        //                }
        //
        //                jsonCommands.forEach(performCommand)
        //            }
        //
        ////            return false
        //        }
        //
        ////        // User is tapping on a link, so we should react accordingly
        ////        if navigationType == .linkClicked {
        ////            if let url = request.url,
        ////                let shouldInteract = delegate?.richEditor?(self, shouldInteractWith: url)
        ////            {
        ////                return shouldInteract
        ////            }
        ////        }
        //        //print("webView:\(webView) decidePolicyForNavigationAction:\(navigationAction) decisionHandler:\(decisionHandler)")
        //
        //        switch navigationAction.navigationType {
        //        case .linkActivated:
        //            if navigationAction.targetFrame == nil {
        //                //self.webView?.loadRequest(navigationAction.request)
        //            }
        //            //            if let url = navigationAction.request.URL where !url.absoluteString.hasPrefix("http://www.myWebSite.com/example") {
        //            //                UIApplication.sharedApplication().openURL(url)
        //            //                print(url.absoluteString)
        //            //                decisionHandler(.Cancel)
        //            //                return
        //            //            }
        //        //            NSLog("Test")//
        //        default:
        //            break
        //        }
        //
        //        decisionHandler(.allow)
    }
}
