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

extension EnvironmentValues {
    @Entry var forceLightModeInMessageBody: Bool = false
}

struct MessageBodyReaderView: UIViewRepresentable {
    @Binding var bodyContentHeight: CGFloat
    let body: MessageBody.HTML
    let urlOpener: URLOpenerProtocol

    func makeUIView(context: Context) -> WKWebView {
        let backgroundColor = UIColor(DS.Color.Background.norm)
        let config = WKWebViewConfiguration()
        config.dataDetectorTypes = [.link]
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        config.setURLSchemeHandler(
            CIDSchemeHandler(embeddedImageProvider: body.embeddedImageProvider),
            forURLScheme: CIDSchemeHandler.handlerScheme
        )

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        webView.isOpaque = false
        webView.backgroundColor = backgroundColor
        webView.scrollView.backgroundColor = backgroundColor
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        #if targetEnvironment(simulator)
            webView.isInspectable = true
        #endif

        config.userContentController.add(context.coordinator, name: Constants.heightChangedHandlerName)
        config.userContentController.addUserScript(.observeHeight)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        updateUIView(uiView)
        uiView.overrideUserInterfaceStyle = context.environment.forceLightModeInMessageBody ? .light : .unspecified
    }

    func updateUIView(_ view: WKWebView) {
        view.loadHTMLString(body.rawBody)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

extension MessageBodyReaderView {
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, @unchecked Sendable {
        let parent: MessageBodyReaderView

        init(_ parent: MessageBodyReaderView) {
            self.parent = parent
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            Task { @MainActor in
                parent.bodyContentHeight = message.body as! CGFloat
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url else {
                return .allow
            }

            parent.urlOpener(url)
            return .cancel
        }
    }
}

extension WKWebView {

    fileprivate func loadHTMLString(_ string: String) {
        loadHTMLString(string, baseURL: nil)
    }

}

extension WKUserScript {
    fileprivate static let observeHeight: WKUserScript = {
        let source = """
            const container = document.documentElement;

            const observer = new ResizeObserver(function() {
                window.webkit.messageHandlers.\(Constants.heightChangedHandlerName).postMessage(container.scrollHeight);
            });

            for (const child of container.children) {
                observer.observe(child);
            }
            """

        return .init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }()
}

private enum Constants {
    static let heightChangedHandlerName = "heightChanged"
}
