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
    internal let body: String
    private let remoteContentMode: RemoteContentLoadingMode
    
    init(body: String, remoteContentMode: RemoteContentLoadingMode) {
        self.body = body
        self.remoteContentMode = remoteContentMode
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

class HTMLSecureLoader: NSObject {
    private var contents: EmailBodyContents?
    private lazy var loopbackScheme: String = "pm-incoming-mail"
    private lazy var loopbackUrl: URL = URL(string: self.loopbackScheme + "://" + UUID().uuidString + ".html")!
    private lazy var request: URLRequest = URLRequest(url: self.loopbackUrl)
    
    private static var css: String = try! String(contentsOfFile: Bundle.main.path(forResource: "editor", ofType: "css")!, encoding: .utf8).replacingOccurrences(of: "\n", with: "")
    private static var domPurifyConstructor: WKUserScript = {
        let raw = try! String(contentsOf: Bundle.main.url(forResource: "purify.min", withExtension: "js")!)
        return WKUserScript(source: raw, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }()
    
    func load(contents: EmailBodyContents, in webView: WKWebView) {
        self.prepareRendering(contents, into: webView.configuration)
        
        if #available(iOS 11.0, *) {
            webView.load(self.request)
        } else {
            webView.loadHTMLString(contents.body, baseURL: URL(string: "about:blank")!)
        }
    }
    
    private func prepareRendering(_ contents: EmailBodyContents, into config: WKWebViewConfiguration) {
        self.contents = contents
        
        let sanitizeRaw = """
        var dirty = document.documentElement.innerHTML.toString();
        var clean1 = DOMPurify.sanitize(dirty);
        var clean2 = DOMPurify.sanitize(clean1, { FORBID_TAGS: ['body', 'style']});
        document.documentElement.innerHTML = clean2;

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
        style.appendChild(document.createTextNode('\(HTMLSecureLoader.css)'));
        document.getElementsByTagName('head')[0].appendChild(style);
        """
        
        let sanitize = WKUserScript(source: sanitizeRaw, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.removeAllUserScripts()
        config.userContentController.addUserScript(HTMLSecureLoader.domPurifyConstructor)
        config.userContentController.addUserScript(sanitize)
    }
    
    func inject(into config: WKWebViewConfiguration) {
        if #available(iOS 11.0, *) {
            config.setURLSchemeHandler(self, forURLScheme: self.loopbackScheme)
        }
    }
}

@available(iOS 11.0, *) extension HTMLSecureLoader: WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let contents = self.contents,
            let bodyData = contents.body.data(using: .unicode) else
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
