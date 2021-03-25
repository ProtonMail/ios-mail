//
//  LinkOpener.swift
//  ProtonMail - Created on 16/09/2019.
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

enum LinkOpener: String, CaseIterable {
    case safari, inAppSafari, chrome, firefox, firefoxFocus, operaMini, operaTouch, brave, edge, yandex, duckDuckGo, onion
    
    private var scheme: String {
        switch self {
        case .safari, .inAppSafari: return "https" // default case
        case .chrome: return "googlechrome"
        case .firefox: return "firefox"
        case .firefoxFocus: return "firefox-focus"
        case .operaMini: return "opera-http"
        case .operaTouch: return "touch-http"
        case .brave: return "brave"
        case .edge: return "microsoft-edge-http"
        case .yandex: return "yandexbrowser-open-url"
        case .duckDuckGo: return "ddgQuickLink"
        case .onion: return "onionhttp"
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
        case .onion: return "Onion Browser"
        case .inAppSafari: return "In-App Safari"
        }
    }
    
    var isInstalled: Bool {
        guard let scheme = URL(string: "\(self.scheme)://") else {
            return false
        }
        return UIApplication.shared.canOpenURL(scheme)
    }
    
    func deeplink(to url: URL) -> URL? {
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           components.scheme == "tel" {
            return  nil
        }

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
        case .onion:
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                components.scheme = components.scheme == "https" ? "onionhttps" : "onionhttp"
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
            if let escapedUrl = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) {
                return URL(string: "brave://open-url?url=\(escapedUrl)")
            }
        case .yandex:
            if let escapedUrl = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                return URL(string: "yandexbrowser-open-url://\(escapedUrl)")
            }
        case .duckDuckGo:
            return URL(string: "ddgQuickLink://\(url)")
            
        case .safari, .inAppSafari:
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
