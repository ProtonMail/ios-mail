//
//  HTMLStringSecureLoader.swift
//  ProtonMail - Created on 15/01/2019.
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


/// Loads web content into WKWebView by means of loadHTMLString(_,baseURL:) method. In order to prevent resources prefetching, loading happens in four stages:
/// 1. required contents are nested into html with <meta> restricting any remote resource loading
/// 2. DOMPurifier is run over this content
/// 3. once sanitization is complete, css and <meta> with reqired CSP are injected into required contents
/// 4. webView reloads sanitized contents body
///
/// Why this is good:
/// - works with iOS 8 - iOS 10
///
/// Why that is not perfect:
/// - CSP is injected as a meta tag string
///
@available(iOS, deprecated: 11.0)
class HTMLStringSecureLoader: NSObject, WebContentsSecureLoader, WKScriptMessageHandler {
    private weak var webView: WKWebView?
    private var contents: WebContents?
    
    func load(contents: WebContents, in webView: WKWebView) {
        self.webView = webView
        self.prepareRendering(contents, into: webView.configuration)
        
        let lockdownBody = """
        <html><head><meta http-equiv="Content-Security-Policy" content="\(WebContents.RemoteContentPolicy.lockdown.cspRaw)"></head>\(contents.body)</html>
        """
        webView.loadHTMLString(lockdownBody, baseURL: URL(string: "about:blank")!)
    }
    
    private func prepareRendering(_ contents: WebContents, into config: WKWebViewConfiguration) {
        self.contents = contents
        
        let sanitizeRaw = """
        var dirty = document.documentElement.innerHTML.toString();
        var clean0 = DOMPurify.sanitize(dirty);
        var clean1 = DOMPurify.sanitize(clean0, \(HTMLStringSecureLoader.domPurifyConfiguration));
        var clean2 = DOMPurify.sanitize(clean1, { WHOLE_DOCUMENT: true, RETURN_DOM: true});
        document.documentElement.replaceWith(clean2)
        
        var metaWidth = document.createElement('meta');
        metaWidth.name = "viewport";
        metaWidth.content = "width=device-width";
        document.getElementsByTagName('head')[0].appendChild(metaWidth);
        
        var metaCSP = document.createElement('meta');
        metaCSP.httpEquiv = "Content-Security-Policy";
        metaCSP.content = "\(contents.contentSecurityPolicy)";
        document.getElementsByTagName('head')[0].appendChild(metaCSP);
        
        var style = document.createElement('style');
        style.type = 'text/css';
        style.appendChild(document.createTextNode('\(WebContents.css)'));
        document.getElementsByTagName('head')[0].appendChild(style);
        
        window.webkit.messageHandlers.loaded.postMessage({'clearBody':document.documentElement.innerHTML});
        """
        
        let sanitize = WKUserScript(source: sanitizeRaw, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.removeAllUserScripts()
        config.userContentController.addUserScript(WebContents.domPurifyConstructor)
        config.userContentController.addUserScript(sanitize)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        PMLog.D(any: message.body)
        guard let dict = message.body as? Dictionary<String, String>,
            let sanitized = dict["clearBody"] else
        {
            return
        }
        userContentController.removeAllUserScripts()
        self.webView?.loadHTMLString(sanitized, baseURL: URL(string: "about:blank")!)
    }
    
    func inject(into config: WKWebViewConfiguration) {
        config.userContentController.add(self, name: "loaded")
    }
}
