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

        webView.isInspectable = WKWebView.inspectabilityEnabled

        config.userContentController.add(context.coordinator, name: Constants.heightChangedHandlerName)
        config.userContentController.addUserScript(.observeHeight(screenWidth: context.environment.mainWindowSize.width))

        context.coordinator.setupRecovery(for: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.receivedBodyDifferentFromBefore(latest: body) {
            loadHTML(in: webView)
        }
        webView.overrideUserInterfaceStyle = context.environment.forceLightModeInMessageBody ? .light : .unspecified
        context.coordinator.urlOpener = context.environment.openURL
    }

    func loadHTML(in webView: WKWebView) {
        let style = """
            <style>
                body {
                    height: auto !important;
                }

                table {
                    height: auto !important;
                    min-height: auto !important;
                }

                @supports (height: fit-content) {
                    html {
                        height: fit-content !important;
                    }
                }
            </style>
            """
        let fixedBody = body.rawBody.replacingOccurrences(of: "</head>", with: "\(style)</head>")
        webView.loadHTMLString(fixedBody, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

extension MessageBodyReaderView {

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, @unchecked Sendable {
        let parent: MessageBodyReaderView
        var urlOpener: URLOpenerProtocol?
        private var previouslyReceivedBody: MessageBody.HTML?
        private weak var webView: WKWebView?
        private var memoryPressureHandler: WebViewMemoryPressureProtocol

        init(
            parent: MessageBodyReaderView,
            memoryPressureHandler: WebViewMemoryPressureProtocol = WebViewMemoryPressureHandler(loggerCategory: .conversationDetail)
        ) {
            self.parent = parent
            self.memoryPressureHandler = memoryPressureHandler
        }

        func setupRecovery(for webView: WKWebView) {
            self.webView = webView
            memoryPressureHandler.contentReload { [weak self] in
                guard let self, let webView = self.webView else { return }
                parent.loadHTML(in: webView)
            }
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive scriptMessage: WKScriptMessage
        ) {
            Task { @MainActor in
                let scriptOutput = scriptMessage.body as! CGFloat
                parent.bodyContentHeight = scriptOutput
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url else {
                return .allow
            }

            urlOpener?(url)
            return .cancel
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            memoryPressureHandler.markWebContentProcessTerminated()
        }

        func receivedBodyDifferentFromBefore(latest body: MessageBody.HTML) -> Bool {
            if previouslyReceivedBody?.rawBody == body.rawBody && previouslyReceivedBody?.options == body.options {
                return false
            } else {
                previouslyReceivedBody = body
                return true
            }
        }
    }
}

extension WKWebView {

    fileprivate func loadHTMLString(_ string: String) {
        loadHTMLString(string, baseURL: nil)
    }

}

extension WKUserScript {
    fileprivate static func observeHeight(screenWidth: CGFloat) -> WKUserScript {
        let source = """
            function notify() {
                measureHeightOnceContentIsLaidOut();
            }

            function measureHeightOnceContentIsLaidOut(retryCount = 0) {
                // Prevent infinite loops (180 frames = ~3 seconds at 60fps)
                const maxRetries = 180;
            
                // If content is not laid out, its width is typically 32 or 80 - this is a good enough heuristic without hard coding magic numbers
                const contentIsLaidOut = document.body.scrollWidth > \(screenWidth / 2)

                if (!contentIsLaidOut && retryCount < maxRetries) {
                    // try again next frame
                    requestAnimationFrame(() => {
                        measureHeightOnceContentIsLaidOut(retryCount + 1);
                    });
                } else {
                    window.webkit.messageHandlers.\(Constants.heightChangedHandlerName).postMessage(document.body.scrollHeight);
                }
            }

            const observer = new ResizeObserver(notify);
            observer.observe(document.body);
            """

        return .init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
}

private enum Constants {
    static let heightChangedHandlerName = "heightChanged"
}
