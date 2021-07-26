//
//  WebContents.swift
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

/// Contains HTML to be loaded into WebView and appropriate CSP
class WebContents: NSObject {
    internal let body: String
    internal let remoteContentMode: RemoteContentPolicy
    
    var bodyForJS: String {
        return self.body.escaped
    }

    init(body: String, remoteContentMode: RemoteContentPolicy) {
        self.body = body
        self.remoteContentMode = remoteContentMode
    }
    
    var contentSecurityPolicy: String {
        return self.remoteContentMode.cspRaw
    }
    
    enum RemoteContentPolicy: Int {
        case allowed, disallowed, lockdown
        
        var cspRaw: String {
            switch self {
            case .lockdown:
                return "default-src 'none'; style-src 'self' 'unsafe-inline';"
                
            case .disallowed: // this cuts off all remote content
                return "default-src 'none'; style-src 'self' 'unsafe-inline'; img-src 'unsafe-inline' data: blob:; script-src 'none';"
                
            case .allowed: // this cuts off only scripts and connections
                return "default-src 'self'; connect-src 'self' blob:; style-src 'self' 'unsafe-inline'; img-src http: https: data: blob: cid:; script-src 'none';"
            }
        }
    }

    enum EmbeddedContentPolicy {
        case disallowed
        case allowed
    }
    
    internal static var css: String = try! String(contentsOfFile: Bundle.main.path(forResource: "editor", ofType: "css")!, encoding: .utf8).replacingOccurrences(of: "\n", with: "")
    internal static var domPurifyConstructor: WKUserScript = {
        let raw = try! String(contentsOf: Bundle.main.url(forResource: "purify.min", withExtension: "js")!)
        return WKUserScript(source: raw, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }()
}
