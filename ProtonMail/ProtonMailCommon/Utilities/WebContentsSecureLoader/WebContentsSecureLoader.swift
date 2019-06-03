//
//  HTMLSecureLoader.swift
//  ProtonMail - Created on 06/01/2019.
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
    

import Foundation
import WebKit

class RenderedContents: NSObject {
    @objc internal dynamic var preheight: CGFloat = 0.1
    @objc internal dynamic var height: CGFloat = 0.1
    
    internal func invalidate() {
        self.preheight = 0.1
        self.height = 0.1
    }
    
    internal var isValid: Bool {
        return self.height != 0.1
    }
}

protocol WebContentsSecureLoader {
    var renderedContents: RenderedContents { get }
    func load(contents: WebContents, in webView: WKWebView)
    func inject(into config: WKWebViewConfiguration)
}
extension WebContentsSecureLoader {
    static var domPurifyConfiguration: String {
        return """
        {
        ALLOWED_URI_REGEXP: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|cid|blob|xmpp|data):|[^a-z]|[a-z+.\\-]+(?:[^a-z+.\\-:]|$))/i,
        ADD_TAGS: ['proton-src', 'base'],
        ADD_ATTR: ['target', 'proton-src'],
        FORBID_TAGS: ['body', 'style', 'input', 'form', 'video', 'audio'],
        FORBID_ATTR: ['srcset']
        }
        """.replacingOccurrences(of: "\n", with: "")
    }
    
    func eject(from config: WKWebViewConfiguration) {
        config.userContentController.removeScriptMessageHandler(forName: "loaded")
    }
}
