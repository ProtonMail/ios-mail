//
//  HTMLStringSecureLoader.swift
//  ProtonMail - Created on 15/01/2019.
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
    internal lazy var renderedContents = RenderedContents()
    private weak var webView: WKWebView?
    private var contents: WebContents?
    
    private var addSpacerIfNeeded: Bool
    
    init(addSpacerIfNeeded: Bool = true) {
        self.addSpacerIfNeeded = addSpacerIfNeeded
        super.init()
    }
    
    func load(contents: WebContents, in webView: WKWebView) {
        self.webView?.stopLoading()
        self.renderedContents.invalidate()
        self.webView?.configuration.userContentController.removeAllUserScripts()
        self.webView?.loadHTMLString("⏱", baseURL: URL(string: "about:blank")!)
        
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
        var clean2 = DOMPurify.sanitize(clean1, { WHOLE_DOCUMENT: true, RETURN_DOM: false});
        document.documentElement.innerHTML = clean2;

        var metaCSP = document.createElement('meta');
        metaCSP.httpEquiv = "Content-Security-Policy";
        metaCSP.content = "\(contents.contentSecurityPolicy)";
        document.getElementsByTagName('head')[0].appendChild(metaCSP);
        
        var style = document.createElement('style');
        style.type = 'text/css';
        style.appendChild(document.createTextNode('\(WebContents.css)'));
        document.getElementsByTagName('head')[0].appendChild(style);
        
        var metaWidth = document.createElement('meta');
        metaWidth.name = "viewport";
        metaWidth.content = "width=device-width";
        var rects = document.body.getBoundingClientRect();
        var ratio = document.body.offsetWidth/document.body.scrollWidth;

        document.getElementsByTagName('head')[0].appendChild(metaWidth);
        """
        
        let message = """
        var items = document.body.getElementsByTagName('*');
        for (var i = items.length; i--;) {
            if (items[i].style.getPropertyValue("height") == "100%") {
                items[i].style.height = "auto";
            };
        };
        window.webkit.messageHandlers.loaded.postMessage({'preheight': ratio * rects.height, 'clearBody':document.documentElement.innerHTML});
        """
        
        let sanitize = WKUserScript(source: sanitizeRaw + message, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.removeAllUserScripts()
        config.userContentController.addUserScript(WebContents.domPurifyConstructor)
        config.userContentController.addUserScript(sanitize)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? Dictionary<String, Any> else {
            assert(false, "Unexpected message sent from JS")
            return
        }
        
        if let sanitized = dict["clearBody"] as? String {
            userContentController.removeAllUserScripts()
            
            let message = """
        var metaWidth = document.querySelector('meta[name="viewport"]');
        metaWidth.content = "width=device-width";
        var ratio = document.body.offsetWidth/document.body.scrollWidth;
        if (ratio < 1) {
            metaWidth.content = metaWidth.content + ", initial-scale=" + ratio + ", maximum-scale=3.0";
        } else {
            ratio = 1;
        };
        window.webkit.messageHandlers.loaded.postMessage({'height': ratio * document.body.scrollHeight});
"""
            let sanitize = WKUserScript(source: message, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            userContentController.addUserScript(sanitize)
            
            self.webView?.loadHTMLString(sanitized, baseURL: URL(string: "about:blank")!)
        }
        
        if let preheight = dict["preheight"] as? Double {
            self.renderedContents.preheight = CGFloat(preheight)
        }
        if let height = dict["height"] as? Double {
            self.renderedContents.height = CGFloat(height)
        }
    }
    
    func inject(into config: WKWebViewConfiguration) {
        config.userContentController.add(self, name: "loaded")
    }
}
