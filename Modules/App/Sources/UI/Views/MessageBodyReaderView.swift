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
    let viewWidth: CGFloat

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

        let userScripts: [WKUserScript] = [
            .adjustLayoutAndObserveHeight(viewWidth: viewWidth),
            .handleEmptyBody,
        ]

        userScripts.forEach(config.userContentController.addUserScript(_:))

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
        let viewport = """
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes">
            """
        var fixedBody = body.rawBody

        if !fixedBody.contains("name=\"viewport\"") {
            fixedBody = fixedBody.replacingOccurrences(of: "<head>", with: "<head>\(viewport)")
        }

        let style = """
            <style>
                html, body {
                    width: 100vw !important;
                    max-width: 100vw !important;
                    overflow-x: hidden !important;
                    box-sizing: border-box;
                }
                img, table, td, th {
                    max-width: 100% !important;
                    height: auto !important;
                    box-sizing: border-box;
                    word-break: break-word;
                }
                p, pre {
                    margin: 1em 0;
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
        fixedBody = fixedBody.replacingOccurrences(of: "</head>", with: "\(style)</head>")

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

extension WKUserScript {
    fileprivate static func adjustLayoutAndObserveHeight(viewWidth: CGFloat) -> WKUserScript {
        let source = """
            (function() {
                const handlerName = "heightChanged";
                let lastHeight = 0;
                let timeoutId = null;

                function sendHeight() {
                    const height = document.documentElement.scrollHeight;
                    if (height !== lastHeight) {
                        lastHeight = height;
                        window.webkit.messageHandlers[handlerName].postMessage(height);
                    }
                }

                // Debounce to avoid spamming
                function debounceSendHeight() {
                    if (timeoutId) clearTimeout(timeoutId);
                    timeoutId = setTimeout(sendHeight, 100);
                }

                // Observe size changes
                const resizeObserver = new ResizeObserver(debounceSendHeight);
                resizeObserver.observe(document.body);

                // Observe DOM mutations (e.g., images loading, content injected)
                const mutationObserver = new MutationObserver(debounceSendHeight);
                mutationObserver.observe(document.body, { childList: true, subtree: true, attributes: true, characterData: true });

                // Send height on DOMContentLoaded and window load
                document.addEventListener("DOMContentLoaded", debounceSendHeight);
                window.addEventListener("load", debounceSendHeight);

                // Fallback: send height after 2 seconds in case nothing else triggers
                setTimeout(sendHeight, 2000);

                // Initial call
                sendHeight();
            })();
            """

        return .init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }

    /// A message can theoretically have an empty <body>. In such case the observed body height will be 0, and the loading spinner would be shown indefinitely.
    fileprivate static let handleEmptyBody = WKUserScript(
        source: """
            if (document.body.childNodes.length == 0) {
                var spacer = document.createElement('br');
                document.body.appendChild(spacer);
            }
            """,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: true
    )
}

private enum Constants {
    static let heightChangedHandlerName = "heightChanged"
}
