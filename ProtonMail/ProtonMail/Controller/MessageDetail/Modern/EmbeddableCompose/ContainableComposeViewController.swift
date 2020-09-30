//
//  EditorViewController.swift
//  ProtonMail - Created on 25/03/2019.
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
        self.webView.isAccessibilityElement = true
        self.webView.accessibilityIdentifier = "ComposerBody"
        
        self.heightObservation = self.htmlEditor.observe(\.contentHeight, options: [.new, .old]) { [weak self] htmlEditor, change in
            guard let self = self, change.oldValue != change.newValue else { return }
            let totalHeight = htmlEditor.contentHeight
            self.updateHeight(to: totalHeight)
            (self.viewModel as! ContainableComposeViewModel).contentHeight = totalHeight
        }
        
        NotificationCenter.default.addObserver(forName: UIMenuController.willShowMenuNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            let saveMenuItem = UIMenuItem(title: LocalString._clear_style, action: #selector(self.removeStyleFromSelection))
            UIMenuController.shared.menuItems = [saveMenuItem]
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
        generateAccessibilityIdentifiers()
    }
    
    @objc func removeStyleFromSelection() {
        self.htmlEditor.removeStyleFromSelection()
    }
    
    override func shouldDefaultObserveContentSizeChanges() -> Bool {
        return false
    }
    
    deinit {
        self.heightObservation = nil
        self.queueObservation = nil
        
        NotificationCenter.default.removeObserver(self)
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
    
    override func addInlineAttachment(_ sid: String, data: Data) -> Promise<Void> {
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
            return Promise()
        }
        return super.addInlineAttachment(sid, data: data)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) { [weak self] in
                    self?.step.insert(.resultAcknowledged)
                }
                
                let alert = UIAlertController(title: "✅", message: LocalString._message_sent_ok_desc, preferredStyle: .alert)
                self.stepAlert = alert
                return
            }
            if step.contains(.sendingFinishedWithError) {
                let alert = UIAlertController(title: "⚠️", message: self.latestError, preferredStyle: .alert)
                alert.addAction(.init(title: "Ok", style: .default, handler: { [weak self] _ in self?.step = .composing }))
                self.stepAlert = alert
                return
            }
            if step.contains(.composingCanceled) {
                let alert = UIAlertController(title: LocalString._closing_draft,
                                                   message: LocalString._please_wait_in_foreground,
                                                   preferredStyle: .alert)
                self.stepAlert = alert
                return
            }
            if step.contains(.sendingStarted) {
                let alert = UIAlertController(title: LocalString._sending_message,
                                               message: LocalString._please_wait_in_foreground,
                                               preferredStyle: .alert)
                
                self.stepAlert = alert
                return
            }
        }
    }
    private var stepAlert: UIAlertController? {
        didSet {
            self.presentedViewController?.dismiss(animated: false)
            if let alert = self.stepAlert {
                self.present(alert, animated: false, completion: nil)
            }
        }
    }
    
    override func cancel() {
        self.step = [.composingCanceled, .resultAcknowledged]
    }
    
    override func sendMessageStepThree() {
        super.sendMessageStepThree()
        self.step = .sendingStarted
    }
    
    override func dismiss() {
        [self.headerView.toContactPicker,
         self.headerView.ccContactPicker,
         self.headerView.bccContactPicker].forEach{ $0.prepareForDesctruction() }
        
        self.queueObservation = sharedMessageQueue.observe(\.queue, options: [.initial]) { [weak self] _, change in
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
        self.stepAlert = nil
        keymaker.lockTheApp()
        UIView.animate(withDuration: 0.25, animations: animationBlock) { _ in
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
    
#endif
}

