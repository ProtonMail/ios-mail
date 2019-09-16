//
//  LinkOpener.swift
//  ProtonMail - Created on 16/09/2019.
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

enum LinkOpener: String, CaseIterable {
    case safari, chrome, firefox, firefoxFocus, operaMini, operaTouch, brave, edge, yandex, duckDuckGo
    
    var scheme: String {
        switch self {
        case .safari: return "https" // default case
        case .chrome: return "googlechrome"
        case .firefox: return "firefox"
        case .firefoxFocus: return "firefox-focus"
        case .operaMini: return "opera-http"
        case .operaTouch: return "touch-http"
        case .brave: return "brave"
        case .edge: return "microsoft-edge-http"
        case .yandex: return "yandexbrowser-open-url"
        case .duckDuckGo: return "ddgQuickLink"
        }
    }
    
    var title: String {
        switch self {
        case .safari: return "Safari"
        case .chrome: return "Chrome"
        case .firefox: return "Firefox"
        case .firefoxFocus: return "Firefox Focus"
        case .operaMini: return "Opera Mini"
        case .operaTouch: return "Opera Touch"
        case .brave: return "Brave"
        case .edge: return "Edge"
        case .yandex: return "Yandex"
        case .duckDuckGo: return "DuckDuckGo"
        }
    }
    
    func deeplink(to url: URL) -> URL? {
        switch self {
        case .chrome:
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                components.scheme = components.scheme == "https" ? "googlechromes" : "googlechrome"
                return components.url
            }
        case .operaMini:
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                components.scheme = components.scheme == "https" ? "opera-https" : "opera-http"
                return components.url
            }
        case .operaTouch:
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                components.scheme = components.scheme == "https" ? "touch-https" : "touch-http"
                return components.url
            }
        case .edge:
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                components.scheme = components.scheme == "https" ? "microsoft-edge-https" : "microsoft-edge-http"
                return components.url
            }
        case .firefox:
            if let escapedUrl = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) {
                return URL(string: "firefox://open-url?url=\(escapedUrl)")
            }
        case .firefoxFocus:
            if let escapedUrl = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) {
                return URL(string: "firefox-focus://open-url?url=\(escapedUrl)")
            }
        case .brave:
            if let escapedUrl = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                return URL(string: "brave://open-url?url=\(escapedUrl)")
            }
        case .yandex:
            if let escapedUrl = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                return URL(string: "yandexbrowser-open-url://\(escapedUrl)")
            }
        case .duckDuckGo:
            return URL(string: "ddgQuickLink://\(url)")
            
        case .safari:
            return url
        }
        
        return nil
    }
}

public extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: generalDelimitersToEncode + subDelimitersToEncode)
        
        return allowed
    }()
}
