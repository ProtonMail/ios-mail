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

class EmailBodyContents {
    internal let body: String
    internal let remoteContentMode: RemoteContentLoadingMode
    
    init(body: String, remoteContentMode: RemoteContentLoadingMode) {
        self.body = body
        self.remoteContentMode = remoteContentMode
    }

    var contentSecurityPolicy: String {
        return self.remoteContentMode.cspRaw
    }
    
    enum RemoteContentLoadingMode {
        case allowed, disallowed, lockdown
        
        var cspRaw: String {
            switch self {
            case .lockdown:
                return "default-src 'none';"
                
            case .disallowed: // this cuts off all remote content
                return "default-src 'none'; style-src 'self' 'unsafe-inline'; img-src 'unsafe-inline' data:;"
                
            case .allowed: // this cuts off only scripts and connections
                return "default-src 'self'; connect-src 'self' blob:; script-src 'none'; style-src 'self' 'unsafe-inline'; img-src http: https: data: blob: cid:;"
            }
        }
    }
    
    internal static var css: String = try! String(contentsOfFile: Bundle.main.path(forResource: "editor", ofType: "css")!, encoding: .utf8).replacingOccurrences(of: "\n", with: "")
    internal static var domPurifyConstructor: WKUserScript = {
        let raw = try! String(contentsOf: Bundle.main.url(forResource: "purify.min", withExtension: "js")!)
        return WKUserScript(source: raw, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }()
}

protocol HTMLSecureLoader {
    func load(contents: EmailBodyContents, in webView: WKWebView)
    func inject(into config: WKWebViewConfiguration)
}

class LeakySecureLoader: NSObject, HTMLSecureLoader, WKScriptMessageHandler {
    private weak var webView: WKWebView?
    private var contents: EmailBodyContents?
    
    func load(contents: EmailBodyContents, in webView: WKWebView) {
        self.webView = webView
        self.prepareRendering(contents, into: webView.configuration)
        
        let lockdownBody = """
        <html><head><meta http-equiv="Content-Security-Policy" content="\(EmailBodyContents.RemoteContentLoadingMode.lockdown.cspRaw)"></head>\(contents.body)</html>
        """
        webView.loadHTMLString(lockdownBody, baseURL: URL(string: "about:blank")!)
    }
    
    private func prepareRendering(_ contents: EmailBodyContents, into config: WKWebViewConfiguration) {
        self.contents = contents
        
        let sanitizeRaw = """
        var dirty = document.documentElement.innerHTML.toString();
        var config = {
        ALLOWED_URI_REGEXP: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|cid|blob|xmpp|data):|[^a-z]|[a-z+.\\-]+(?:[^a-z+.\\-:]|$))/i,
        ADD_TAGS: ['proton-src', 'base'],
        ADD_ATTR: ['target', 'proton-src'],
        FORBID_TAGS: ['body', 'style', 'input', 'form'],
        FORBID_ATTR: ['srcset']
        };
        var clean1 = DOMPurify.sanitize(dirty, config);
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
        style.appendChild(document.createTextNode('\(EmailBodyContents.css)'));
        document.getElementsByTagName('head')[0].appendChild(style);
        
        window.webkit.messageHandlers.loaded.postMessage({'clearBody':document.documentElement.innerHTML});
        """
        
        let sanitize = WKUserScript(source: sanitizeRaw, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.removeAllUserScripts()
        config.userContentController.addUserScript(EmailBodyContents.domPurifyConstructor)
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


@available(iOS 11.0, *) 
class BulletproofSecureLoader: NSObject, HTMLSecureLoader, WKScriptMessageHandler {
    private weak var webView: WKWebView?
    private var blockRules: WKContentRuleList?
    private var contents: EmailBodyContents?
    
    private static var loopbackScheme: String = "pm-incoming-mail"
    
    func load(contents: EmailBodyContents, in webView: WKWebView) {
        self.webView = webView
        
        let urlString = (UUID().uuidString + ".proton").lowercased()
        var request = URLRequest(url: URL(string: BulletproofSecureLoader.loopbackScheme + "://" + urlString)!)
        request.httpBody = contents.body.data(using: .unicode)
        
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
         }]
        """
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "ContentBlockingRules",
                                                                encodedContentRuleList: blockRules) { contentRuleList, error in
            assert(error == nil, "Error compiling content blocker rules: \(error!.localizedDescription)")
            self.blockRules = contentRuleList
            self.prepareRendering(contents, into: webView.configuration)

            webView.load(request)
        }
    }
    
    private func prepareRendering(_ contents: EmailBodyContents, into config: WKWebViewConfiguration) {
        self.contents = contents
        
        let sanitizeRaw = """
        var dirty = document.documentElement.outerHTML.toString();
        var config = {
            ALLOWED_URI_REGEXP: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|cid|blob|xmpp|data):|[^a-z]|[a-z+.\\-]+(?:[^a-z+.\\-:]|$))/i,
            ADD_TAGS: ['proton-src', 'base'],
            ADD_ATTR: ['target', 'proton-src'],
            FORBID_TAGS: ['body', 'style', 'input', 'form'],
            FORBID_ATTR: ['srcset']
        };
        var clean0 = DOMPurify.sanitize(dirty);
        var clean1 = DOMPurify.sanitize(clean0, config);
        var clean2 = DOMPurify.sanitize(clean1, { WHOLE_DOCUMENT: true, RETURN_DOM: true});
        document.documentElement.replaceWith(clean2);
        
        var metaWidth = document.createElement('meta');
        metaWidth.name = "viewport";
        metaWidth.content = "width=device-width";
        document.getElementsByTagName('head')[0].appendChild(metaWidth);

        var style = document.createElement('style');
        style.type = 'text/css';
        style.appendChild(document.createTextNode('\(EmailBodyContents.css)'));
        document.getElementsByTagName('head')[0].appendChild(style);
        
        window.webkit.messageHandlers.loaded.postMessage({'dirtyBody': dirty, 'clearBody': document.documentElement.outerHTML.toString()});
        """
        
        let sanitize = WKUserScript(source: sanitizeRaw, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.removeAllUserScripts()
        config.userContentController.addUserScript(EmailBodyContents.domPurifyConstructor)
        config.userContentController.addUserScript(sanitize)

        config.userContentController.add(self.blockRules!)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        PMLog.D(any: message.body)
        if let dict = message.body as? Dictionary<String, String>,
            let sanitized = dict["clearBody"]
        {
            userContentController.removeAllContentRuleLists()
            userContentController.removeAllUserScripts()
            var request = URLRequest(url: URL(string: BulletproofSecureLoader.loopbackScheme + "://" + UUID().uuidString + ".html")!)
            request.httpBody = sanitized.data(using: .unicode)
            self.webView?.load(request)
            return
        }
    }
    
    func inject(into config: WKWebViewConfiguration) {
        config.userContentController.add(self, name: "loaded")
        config.setURLSchemeHandler(self, forURLScheme: BulletproofSecureLoader.loopbackScheme)
    }
}

@available(iOS 11.0, *) extension BulletproofSecureLoader: WKURLSchemeHandler {
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
        if let bodyData = urlSchemeTask.request.httpBody {
            urlSchemeTask.didReceive(bodyData)
        }
        urlSchemeTask.didFinish()
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        assert(false, "webView should not stop urlSchemeTask cuz we're providing response locally")
    }
}
