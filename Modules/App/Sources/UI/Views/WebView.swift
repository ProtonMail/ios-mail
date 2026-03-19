// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import InboxCore
import InboxDesignSystem
import SwiftUI
import WebKit
import proton_app_uniffi

struct WebView: UIViewRepresentable {
    let url: URL
    let sessionID: String
    let configureUserContentController: (WKUserContentController) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let backgroundColor = UIColor(DS.Color.Background.norm)
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = backgroundColor
        webView.scrollView.backgroundColor = backgroundColor
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        configureUserContentController(webView.configuration.userContentController)

        let cookie = HTTPCookie(properties: [
            .name: "Session-Id",
            .value: sessionID,
            .domain: ".\(ApiConfig.current.envId.domain)",
            .path: "/",
            .secure: "TRUE",
            .init(rawValue: "HttpOnly"): "TRUE",
        ])

        if let cookie {
            configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                webView.load(URLRequest(url: url))
            }
        } else {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
