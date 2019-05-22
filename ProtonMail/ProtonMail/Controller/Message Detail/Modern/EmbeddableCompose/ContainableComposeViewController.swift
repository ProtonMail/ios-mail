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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.scrollView.clipsToBounds = false
        
        self.heightObservation = self.htmlEditor.observe(\.contentHeight, options: [.new, .old]) { [weak self] htmlEditor, change in
            guard let self = self, change.oldValue != change.newValue else { return }
            let totalHeight = htmlEditor.contentHeight
            self.updateHeight(to: totalHeight)
            (self.viewModel as! ContainableComposeViewModel).contentHeight = totalHeight
        }
    }
    
    override func shouldDefaultObserveContentSizeChanges() -> Bool {
        return false
    }
    
    deinit {
        self.heightObservation = nil
    }
    
    override func caretMovedTo(_ offset: CGPoint) {
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
                self.latestErrorBanner = BannerView(appearance: .red, message: LocalString._the_total_attachment_size_cant_be_bigger_than_25mb, buttons: nil, offset: 8.0)
                #if !APP_EXTENSION
                UIApplication.shared.sendAction(#selector(BannerPresenting.presentBanner(_:)), to: nil, from: self, for: nil)
                #else
                // FIXME: send message via window
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
}
