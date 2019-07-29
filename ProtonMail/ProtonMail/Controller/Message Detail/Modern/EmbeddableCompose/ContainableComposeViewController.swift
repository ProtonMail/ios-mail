//
//  EditorViewController.swift
//  ProtonMail - Created on 25/03/2019.
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


/// The class hierarchy is following: ContainableComposeViewController > ComposeViewController > HorizontallyScrollableWebViewContainer > UIViewController
///
/// HtmlEditorBehavior only adds some functionality to HorizontallyScrollableWebViewContainer's webView, is not a UIView or webView's delegate any more. ComposeViewController is tightly coupled with ComposeHeaderViewController and needs separate refactor, while ContainableComposeViewController and HorizontallyScrollableWebViewContainer contain absolute minimum of logic they need: logic allowing to embed composer into tableView cell and logic allowing 2D scroll in fullsize webView.
///
class ContainableComposeViewController: ComposeViewController, BannerRequester {
    private var latestErrorBanner: BannerView?
    private var heightObservation: NSKeyValueObservation!
    private var queueObservation: NSKeyValueObservation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.scrollView.clipsToBounds = false
        
        self.heightObservation = self.htmlEditor.observe(\.contentHeight, options: [.new, .old, .initial]) { [weak self] htmlEditor, change in
            guard let self = self, change.oldValue != change.newValue else { return }
            let totalHeight = htmlEditor.contentHeight
            self.updateHeight(to: totalHeight)
            (self.viewModel as! ContainableComposeViewModel).contentHeight = totalHeight
        }
        
        // notifications
        #if APP_EXTENSION
        NotificationCenter.default.addObserver(forName: NSError.errorOccuredNotification, object: nil, queue: nil) { [weak self] notification in
            self?.latestError = notification.userInfo?["text"] as? String
            self?.step.insert(.sendingFinishedWithError)
        }
        NotificationCenter.default.addObserver(forName: NSError.noErrorNotification, object: nil, queue: nil) { [weak self] notification in
            self?.step.insert(.sendingFinishedSuccessfully)
        }
        #endif
    }
    
    override func shouldDefaultObserveContentSizeChanges() -> Bool {
        return false
    }
    
    deinit {
        self.heightObservation = nil
        self.queueObservation = nil
    }
    
    override func caretMovedTo(_ offset: CGPoint) {
        self.stopInertia()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) { [weak self] in
            guard let self = self, let enclosingScroller = self.enclosingScroller else { return }
             // approx height and width of our text row
            let сaretBounds = CGSize(width: 100, height: 100)
            
            // horizontal
            let offsetAreaInWebView = CGRect(x: offset.x - сaretBounds.width/2, y: 0, width: сaretBounds.width, height: 1)
            self.webView.scrollView.scrollRectToVisible(offsetAreaInWebView, animated: true)
            
            // vertical
            let offsetAreaInCell = CGRect(x: 0, y: offset.y - сaretBounds.height/2, width: 1, height: сaretBounds.height)
            let offsetArea = self.view.convert(offsetAreaInCell, to: enclosingScroller.scroller)
            enclosingScroller.scroller.scrollRectToVisible(offsetArea, animated: true)
        }
    }
    
    override func composeViewHideExpirationView(_ composeView: ComposeHeaderViewController) {
        super.composeViewHideExpirationView(composeView)
        self.enclosingScroller?.scroller.isScrollEnabled = true
    }
    
    override func composeViewDidTapExpirationButton(_ composeView: ComposeHeaderViewController) {
        super.composeViewDidTapExpirationButton(composeView)
        self.enclosingScroller?.scroller.isScrollEnabled = false
    }
    
    override func webViewPreferences() -> WKPreferences {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = false
        return preferences
    }
    
    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.htmlEditor.webView(webView, didFinish: navigation)
        super.webView(webView, didFinish: navigation)
    }
    
    override func addInlineAttachment(_ sid: String, data: Data) {
        guard (self.viewModel as? ContainableComposeViewModel)?.validateAttachmentsSize(withNew: data) == true else {
            DispatchQueue.main.async {
                self.latestErrorBanner?.remove(animated: true)
                self.latestErrorBanner = BannerView(appearance: .red, message: LocalString._the_total_attachment_size_cant_be_bigger_than_25mb, buttons: nil, offset: 8.0)
                #if !APP_EXTENSION
                UIApplication.shared.sendAction(#selector(BannerPresenting.presentBanner(_:)), to: nil, from: self, for: nil)
                #else
                // hackish way to get to UIApplication in Share extension
                (self.view.window?.next as? UIApplication)?.sendAction(#selector(BannerPresenting.presentBanner(_:)), to: nil, from: self, for: nil)
                #endif
            }
            
            self.htmlEditor.remove(embedImage: "cid:\(sid)")
            return
        }
        super.addInlineAttachment(sid, data: data)
    }
    
    func errorBannerToPresent() -> BannerView? {
        return self.latestErrorBanner
    }

// TODO: when refactoring ComposeViewController, place this stuff in a higher level ViewModel and Controller - ComposeContainer
#if APP_EXTENSION
    private var latestError: String?
    private struct SendingStep: OptionSet {
        let rawValue: Int
        
        static var composing = SendingStep(rawValue: 1 << 0)
        static var composingCanceled = SendingStep(rawValue: 1 << 1)
        static var sendingStarted = SendingStep(rawValue: 1 << 2)
        static var sendingFinishedWithError = SendingStep(rawValue: 1 << 3)
        static var sendingFinishedSuccessfully = SendingStep(rawValue: 1 << 4)
        static var resultAcknowledged = SendingStep(rawValue: 1 << 5)
        static var queueIsEmpty = SendingStep(rawValue: 1 << 6)
    }
    
    private var step: SendingStep = .composing {
        didSet {
            guard !step.contains(.composing) else {
                return
            }
            if step.contains(.resultAcknowledged) && step.contains(.queueIsEmpty) {
                self.dismissAnimation()
                return
            }

            if step.contains(.sendingFinishedSuccessfully) {
                let alert = UIAlertController(title: "✅", message: LocalString._message_sent_ok_desc, preferredStyle: .alert)
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                    self.step.insert(.resultAcknowledged)
                }
                self.stepAlert = alert
                return
            }
            if step.contains(.sendingFinishedWithError) {
                let alert = UIAlertController(title: "⚠️", message: self.latestError, preferredStyle: .alert)
                alert.addAction(.init(title: "Ok", style: .default, handler: { _ in self.step = .composing }))
                self.stepAlert = alert
                return
            }
            if step.contains(.composingCanceled) {
                self.stepAlert = UIAlertController(title: LocalString._closing_draft,
                                                   message: LocalString._please_wait_in_foreground,
                                                   preferredStyle: .alert)
                return
            }
            if step.contains(.sendingStarted) {
                self.stepAlert = UIAlertController(title: LocalString._sending_message,
                                                   message: LocalString._please_wait_in_foreground,
                                                   preferredStyle: .alert)
                return
            }
        }
    }
    private var stepAlert: UIAlertController? {
        willSet {
            self.stepAlert?.dismiss(animated: false)
        }
        didSet {
            if let alert = self.stepAlert {
                self.present(alert, animated: false, completion: nil)
            }
        }
    }
    
    override func cancelAction(_ value: UIBarButtonItem) {
        super.cancelAction(value)
        self.step = .composingCanceled
        self.step.insert(.resultAcknowledged)
    }
    
    override func sendMessageStepThree() {
        super.sendMessageStepThree()
        self.step = .sendingStarted
    }
    
    override func dismiss() {
        [self.headerView.toContactPicker,
         self.headerView.ccContactPicker,
         self.headerView.bccContactPicker].forEach{ $0.prepareForDesctruction() }
        
        self.queueObservation = sharedMessageQueue.observe(\.queue) { [weak self] _, change in
            if sharedMessageQueue.queue.isEmpty {
                self?.step.insert(.queueIsEmpty)
            }
        }
    }
    
    private func dismissAnimation() {
        let animationBlock: ()->Void = { [weak self] in
            if let view = self?.navigationController?.view {
                view.transform = CGAffineTransform(translationX: 0, y: view.frame.size.height)
            }
        }
        keymaker.lockTheApp()
        UIView.animate(withDuration: 0.25, animations: animationBlock) { _ in
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
    
#endif
}

