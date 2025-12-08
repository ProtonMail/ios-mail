//
// Copyright (c) 2025 Proton Technologies AG
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

import InboxDesignSystem
import WebKit

public extension WKWebView {
    static func `default`(configuration: WKWebViewConfiguration) -> WKWebView {
        let backgroundColor = UIColor(DS.Color.Background.norm)

        let webView = WKWebViewWithNoAccessoryView(frame: .zero, configuration: configuration)
        webView.backgroundColor = backgroundColor
        webView.isOpaque = false
        webView.scrollView.backgroundColor = backgroundColor
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.isScrollEnabled = false

        #if DEBUG
            webView.isInspectable = true
        #endif

        return webView
    }
}

private class WKWebViewWithNoAccessoryView: WKWebView {
    override var inputAccessoryView: UIView? {
        return nil
    }
}
