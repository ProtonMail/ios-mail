//
//  HTTPRequestSecureLoader.swift
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

/// Loads web content into WKWebView by means of load(_:) and inner URLRequest method. In order to prevent resources prefetching, loading happens in a number of stages:
/// 1. webView gets a WKContentRuleList restricting any loads other than current url and a custom scheme handler
/// 2. construct URLRequest for that url and ask webView to start loading
/// 3. webView asks custom scheme handler to handle the request, we create response with required data and reqired CSP in HTTP headers, return it to webView
/// 4. DOMPurifier sanitizes contents, once sanitization is complete, css is injected into required contents
/// 5. webView switches off content rule list and reloads sanitized contents body
///
/// Why this is good:
/// - object-oriented approach to CSP and blocking of early resources loading
///
/// Why that is not perfect:
/// - WKContentRuleList and WKURLSchemeHandler are not supported until iOS 11
///
@available(iOS 11.0, *)
class HTTPRequestSecureLoader: NSObject, WebContentsSecureLoader, WKScriptMessageHandler {
    internal let renderedContents = RenderedContents()
    
    private weak var webView: WKWebView?
    private var blockRules: WKContentRuleList?
    private var contents: WebContents?
    
    private static var loopbackScheme: String = "pm-incoming-mail"
    private var loopbacks: Dictionary<URL, Data> = [:]
    
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
        
        let urlString = (UUID().uuidString + ".proton").lowercased()
        let url = URL(string: HTTPRequestSecureLoader.loopbackScheme + "://" + urlString)!
        let request = URLRequest(url: url)
        let data = contents.body.data(using: .unicode)
        self.loopbacks[url] = data
        
        let blockRules = """
        [{
            "trigger": {
                "url-filter": ".*"
            },
            "action": {
                "type": "block"
            }
        },
        {
            "trigger": {
                "url-filter": "\(urlString)"
            },
            "action": {
                "type": "ignore-previous-rules"
            }
        }
        ]
        """
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "ContentBlockingRules", encodedContentRuleList: blockRules) { contentRuleList, error in
            guard error == nil, let compiledRule = contentRuleList else {
                assert(error == nil, "Error compiling content blocker rules: \(error!.localizedDescription)")
                return
            }
            self.blockRules = compiledRule
            self.prepareRendering(contents, into: webView.configuration)
            webView.load(request)
        }
    }
    
    private func prepareRendering(_ contents: WebContents, into config: WKWebViewConfiguration) {
        self.contents = contents
        
        let sanitizeRaw = """
        var dirty = document.documentElement.outerHTML.toString();
        var clean0 = DOMPurify.sanitize(dirty);
        var clean1 = DOMPurify.sanitize(clean0, \(HTTPRequestSecureLoader.domPurifyConfiguration));
        var clean2 = DOMPurify.sanitize(clean1, { WHOLE_DOCUMENT: true, RETURN_DOM: true});
        document.documentElement.replaceWith(clean2);
        
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
        window.webkit.messageHandlers.loaded.postMessage({'preheight': ratio * rects.height, 'clearBody': document.documentElement.outerHTML.toString()});
        """
        
        let sanitize = WKUserScript(source: sanitizeRaw + message, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.removeAllUserScripts()
        config.userContentController.addUserScript(WebContents.domPurifyConstructor)
        config.userContentController.addUserScript(sanitize)
        
        config.userContentController.add(self.blockRules!)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? Dictionary<String, Any> else {
            assert(false, "Unexpected message sent from JS")
            return
        }
        
        if let sanitized = dict["clearBody"] as? String {
            userContentController.removeAllContentRuleLists()
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
            
            let urlString = (UUID().uuidString + ".proton").lowercased()
            let url = URL(string: HTTPRequestSecureLoader.loopbackScheme + "://" + urlString)!
            let request = URLRequest(url: url)
            let data = sanitized.data(using: .unicode)
            self.loopbacks[url] = data
            
            self.webView?.load(request)
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
        config.setURLSchemeHandler(self, forURLScheme: HTTPRequestSecureLoader.loopbackScheme)
    }
}

@available(iOS 11.0, *) extension HTTPRequestSecureLoader: WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let contents = self.contents else {
            urlSchemeTask.didFinish()
            return
        }
        
        let headers: Dictionary<String, String> = [
            "Content-Type": "text/html",
            "Cross-Origin-Resource-Policy": "Same",
            "Content-Security-Policy": contents.contentSecurityPolicy
        ]
        
        let response = HTTPURLResponse(url: urlSchemeTask.request.url!, statusCode: 200, httpVersion: "HTTP/2", headerFields: headers)!
        urlSchemeTask.didReceive(response)
        if let url = urlSchemeTask.request.url,
            let found = self.loopbacks[url] {
            urlSchemeTask.didReceive(found)
        }
        urlSchemeTask.didFinish()
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        assert(false, "webView should not stop urlSchemeTask cuz we're providing response locally")
    }
}
