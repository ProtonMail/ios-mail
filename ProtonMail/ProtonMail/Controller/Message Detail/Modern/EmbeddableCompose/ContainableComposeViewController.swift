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

class ContainableComposeViewController: ComposeViewController {
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
    
    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        self.htmlEditor.webView(webView, wasAskedToDecidePolicyFor: navigationAction)
        super.webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
    }
    
    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.htmlEditor.webView(webView, didFinish: navigation)
        super.webView(webView, didFinish: navigation)
    }
}
