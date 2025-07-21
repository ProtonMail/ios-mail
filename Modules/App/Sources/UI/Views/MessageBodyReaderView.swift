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
    @Environment(\.webViewPrintingRegistrar) var webViewPrintingRegistrar
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
        context.environment.webViewPrintingRegistrar.register(webView: webView)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.receivedBodyDifferentFromBefore(latest: body) {
            loadHTML(in: webView)
        }
        webView.overrideUserInterfaceStyle = context.environment.forceLightModeInMessageBody ? .light : .unspecified
        context.coordinator.urlOpener = context.environment.openURL
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeAllScriptMessageHandlers()
    }

    func loadHTML(in webView: WKWebView) {
        let style = """
            <style>
                p,pre {
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

extension WKUserScript {
    fileprivate static func adjustLayoutAndObserveHeight(viewWidth: CGFloat) -> WKUserScript {
        let source = """
            function executeOnceContentIsLaidOut(callback) {
                // This is a good enough heuristic without hard coding magic numbers
                const isContentLaidOut = document.body.offsetWidth > \(viewWidth / 2);

                if (isContentLaidOut) {
                    callback();
                } else {
                    // try again next frame
                    requestAnimationFrame(() => {
                        executeOnceContentIsLaidOut(callback);
                    });
                }
            }

            function setViewportInitialScale(ratio) {
                var metaWidth = document.querySelector('meta[name="viewport"]');
                metaWidth.content = "width=device-width, initial-scale=" + ratio + ", maximum-scale=3.0, user-scalable=yes";
            }

            function startSendingHeightToSwiftUI(ratio) {
                const observer = new ResizeObserver(() => {
                    var height = document.documentElement.scrollHeight * ratio;
                    window.webkit.messageHandlers.\(Constants.heightChangedHandlerName).postMessage(height);
                });

                observer.observe(document.body);
            }

            executeOnceContentIsLaidOut(() => {
                const ratio = document.body.offsetWidth / document.body.scrollWidth;
                setViewportInitialScale(ratio);
                startSendingHeightToSwiftUI(ratio);
            });
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
