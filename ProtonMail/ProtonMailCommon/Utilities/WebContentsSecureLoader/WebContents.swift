//
//  WebContents.swift
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

/// Contains HTML to be loaded into WebView and appropriate CSP
class WebContents {
    internal let body: String
    internal let remoteContentMode: RemoteContentPolicy
    
    init(body: String, remoteContentMode: RemoteContentPolicy) {
        self.body = body
        self.remoteContentMode = remoteContentMode
    }
    
    var contentSecurityPolicy: String {
        return self.remoteContentMode.cspRaw
    }
    
    enum RemoteContentPolicy {
        case allowed, disallowed, lockdown
        
        var cspRaw: String {
            switch self {
            case .lockdown:
                return "default-src 'none';"
                
            case .disallowed: // this cuts off all remote content
                return "default-src 'none'; style-src 'self' 'unsafe-inline'; img-src 'unsafe-inline' data:; script-src 'none';"
                
            case .allowed: // this cuts off only scripts and connections
                return "default-src 'self'; connect-src 'self' blob:; style-src 'self' 'unsafe-inline'; img-src http: https: data: blob: cid:; script-src 'none';"
            }
        }
    }
    
    internal static var css: String = try! String(contentsOfFile: Bundle.main.path(forResource: "editor", ofType: "css")!, encoding: .utf8).replacingOccurrences(of: "\n", with: "")
    internal static var domPurifyConstructor: WKUserScript = {
        let raw = try! String(contentsOf: Bundle.main.url(forResource: "purify.min", withExtension: "js")!)
        return WKUserScript(source: raw, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }()
}
