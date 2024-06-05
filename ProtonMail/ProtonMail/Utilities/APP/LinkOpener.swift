//
//  LinkOpener.swift
//  Proton Mail - Created on 16/09/2019.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import UIKit

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
        case .safari: return "System Default"
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
        return ProcessInfo.isRunningUnitTests || UIApplication.shared.canOpenURL(scheme)
    }

    func deeplink(to url: URL) -> URL {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           components.scheme == "tel" {
            return url
        }

        guard isInstalled else {
            return url
        }

        var specificURL: URL?
        switch self {
        case .chrome, .edge, .onion, .operaMini, .operaTouch:
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                components.scheme = components.scheme == "https" ? "\(scheme)s" : scheme
                specificURL = components.url
            }
        case .brave, .firefox, .firefoxFocus:
            if let escapedUrl = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) {
                specificURL = URL(string: "\(scheme)://open-url?url=\(escapedUrl)")
            }
        case .yandex:
            if let escapedUrl = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                specificURL = URL(string: "\(scheme)://\(escapedUrl)")
            }
        case .duckDuckGo:
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                components.scheme = scheme
                specificURL = components.url
            }
        case .safari, .inAppSafari:
            break
        }

        return specificURL ?? url
    }
}
