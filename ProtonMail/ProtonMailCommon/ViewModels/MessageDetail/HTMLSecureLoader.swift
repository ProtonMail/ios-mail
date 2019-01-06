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

struct EmailBodyContents {
    private let rawBody: String
    let remoteContentMode: RemoteContentLoadingMode
    
    init(body rawBody: String, remoteContentMode: RemoteContentLoadingMode) {
        self.rawBody = rawBody
        self.remoteContentMode = remoteContentMode
    }
    
    var secureBody: String {
        // TODO: inject purifier here
        return self.rawBody
    }
    
    enum RemoteContentLoadingMode {
        case allowed, disallowed // TODO: .noImages
    }
}

@available(iOS 11.0, *) class HTMLSecureLoader: NSObject, WKURLSchemeHandler {
    private var contents: EmailBodyContents?
    
    func load(contents: EmailBodyContents, in webView: WKWebView) {
        self.contents = contents
        webView.load(self.request)
    }
    
    func inject(into config: WKWebViewConfiguration) {
        config.setURLSchemeHandler(self, forURLScheme: self.loopbackScheme)
    }
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let mode = self.contents?.remoteContentMode,
            let bodyData = self.contents?.secureBody.data(using: .unicode) else
        {
            urlSchemeTask.didFinish()
            return
        }
        
        var headers: Dictionary<String, String> = [
            "Content-Type": "text/html",
            "Cross-Origin-Resource-Policy": "Same"
        ]
        
        switch mode {
        case .disallowed: // this cuts off all remote content
            headers["Content-Security-Policy"] = "default-src 'none'; style-src 'self' 'unsafe-inline';"
            
        case .allowed: // this cuts off only scripts and connections
            headers["Content-Security-Policy"] = "default-src 'self'; connect-src 'self' blob:; script-src 'none'; style-src 'self' 'unsafe-inline'; img-src http: https: data: blob: cid:;"
        }
        
        let response = HTTPURLResponse(url: self.loopbackUrl, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(bodyData)
        urlSchemeTask.didFinish()
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        assert(false, "webView should not stop urlSchemeTask cuz we're providing response locally")
    }
    
    private var loopbackScheme: String {
        return "pm-incoming-mail"
    }
    
    private var loopbackUrl: URL {
        let url = URL(string: self.loopbackScheme + "://" + UUID().uuidString + ".html")!
        return url
    }
    
    var request: URLRequest {
        return URLRequest(url: self.loopbackUrl)
    }
}
