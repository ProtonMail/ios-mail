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

import DesignSystem
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView  {
        let backgroundColor = UIColor(DS.Color.Background.norm)
        let wkwebView = WKWebView()
        let request = URLRequest(url: url)
        wkwebView.load(request)
        wkwebView.isOpaque = false
        wkwebView.backgroundColor = backgroundColor
        wkwebView.scrollView.backgroundColor = backgroundColor
        wkwebView.scrollView.contentInsetAdjustmentBehavior = .never
        return wkwebView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
