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
import JavaScriptCore

class EmailBodyContents {
    private let body: String
    private let remoteContentMode: RemoteContentLoadingMode
    
    private lazy var vm = JSVirtualMachine()
    private lazy var context: JSContext = {
        let context = JSContext(virtualMachine: self.vm)!
        context.exceptionHandler = { context, exception in
            PMLog.D(exception.debugDescription)
        }
        return context
    }()
    
    init(body: String, remoteContentMode: RemoteContentLoadingMode) {
        self.body = body
        self.remoteContentMode = remoteContentMode
    }
    
    var fullBody: String {
        let css = try! String(contentsOfFile: Bundle.main.path(forResource: "editor", ofType: "css")!, encoding: String.Encoding.utf8)
        let meta: String = {
            if #available(iOS 11.0, *) {
                // in this case we will use preferable way for CSP - HTTP headers
                return """
                <meta name="viewport" content="width=device-width, target-densitydpi=device-dpi, initial-scale=\(EmailView.kDefautWebViewScale)">
                """
            } else {
                // older iOS versions of WKWebView will load html without http headers, so we have to fallback to meta tag for CSP
                return """
                <meta name="viewport" content="width=device-width, target-densitydpi=device-dpi, initial-scale=\(EmailView.kDefautWebViewScale)">
                <meta http-equiv="Content-Security-Policy" content="\(self.contentSecurityPolicy)">
                """
            }
        }()
        
        return "<style>\(css)</style>\(meta)<div id='pm-body' class='inbox-body'>\(self.body)</div>"
    }
    
    
    var contentSecurityPolicy: String {
        switch self.remoteContentMode {
        case .disallowed: // this cuts off all remote content
            return "default-src 'none'; style-src 'self' 'unsafe-inline';"
            
        case .allowed: // this cuts off only scripts and connections
            return "default-src 'self'; connect-src 'self' blob:; script-src 'none'; style-src 'self' 'unsafe-inline'; img-src http: https: data: blob: cid:;"
        }
    }
    
    enum RemoteContentLoadingMode {
        case allowed, disallowed
    }
}

class HTMLSecureLoader: NSObject, WKScriptMessageHandler {
    private var contents: EmailBodyContents?
    private lazy var loopbackScheme: String = "pm-incoming-mail"
    private lazy var loopbackUrl: URL = URL(string: self.loopbackScheme + "://" + UUID().uuidString + ".html")!
    private lazy var request: URLRequest = URLRequest(url: self.loopbackUrl)
    
    func load(contents: EmailBodyContents, in webView: WKWebView) {
        self.contents = contents
        
        if #available(iOS 11.0, *) {
            webView.load(self.request)
        } else {
            webView.loadHTMLString(contents.fullBody, baseURL: URL(string: "about:blank")!)
        }
    }
    
    func inject(into config: WKWebViewConfiguration) {
        let domPurifyRaw = try! String(contentsOf: Bundle.main.url(forResource: "purify.min", withExtension: "js")!)
        let domPurify = WKUserScript(source: domPurifyRaw, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        
        let sanitizeRaw = """
        var clear = DOMPurify.sanitize(document.documentElement.innerHTML.toString());
        window.webkit.messageHandlers.loaded.postMessage({'clearBody':clear});
        document.documentElement.innerHTML = clear;
        """
        let sanitize = WKUserScript(source: sanitizeRaw, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        config.userContentController.add(self, name: "loaded")
        config.userContentController.removeAllUserScripts()
        config.userContentController.addUserScript(domPurify)
        config.userContentController.addUserScript(sanitize)
        
        if #available(iOS 11.0, *) {
            config.setURLSchemeHandler(self, forURLScheme: self.loopbackScheme)
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        PMLog.D(any: message.body)
    }
}

@available(iOS 11.0, *) extension HTMLSecureLoader: WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let contents = self.contents,
            let bodyData = contents.fullBody.data(using: .unicode) else
        {
            urlSchemeTask.didFinish()
            return
        }
        
        let headers: Dictionary<String, String> = [
            "Content-Type": "text/html",
            "Cross-Origin-Resource-Policy": "Same",
            "Content-Security-Policy": contents.contentSecurityPolicy
        ]
        
        let response = HTTPURLResponse(url: self.loopbackUrl, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(bodyData)
        urlSchemeTask.didFinish()
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        assert(false, "webView should not stop urlSchemeTask cuz we're providing response locally")
    }
}
