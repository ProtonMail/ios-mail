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
import SwiftUI
import WebKit

extension EnvironmentValues {
    @Entry var forceLightModeInMessageBody: Bool = false
    @Entry var orientationChangeInProgress: Bool = false
}

struct MessageBodyReaderView: UIViewRepresentable {
    @Binding var bodyContentHeight: CGFloat
    @State var schemeHandler: UniversalSchemeHandler
    let body: MessageBody.HTML
    let viewWidth: CGFloat
    let confirmLink: Bool

    init(
        bodyContentHeight: Binding<CGFloat>,
        body: MessageBody.HTML,
        schemeHandler: UniversalSchemeHandler,
        viewWidth: CGFloat,
        confirmLink: Bool
    ) {
        self._bodyContentHeight = .init(projectedValue: bodyContentHeight)
        self.body = body
        self.viewWidth = viewWidth
        self.confirmLink = confirmLink
        self.schemeHandler = schemeHandler
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration.default(handler: schemeHandler)
        let webView = WKWebView.default(configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isInspectable = WKWebView.inspectabilityEnabled

        for handlerName in HandlerName.allCases {
            config.userContentController.add(context.coordinator, name: handlerName.rawValue)
        }

        var userScripts: [AppScript] = [
            .redirectConsoleLogToAppLogger,
            .handleEmptyBody,
            .stylePropertyCoding,
            .stripUnwantedStyleProperties,
            .adjustLayoutAndObserveHeight(viewWidth: viewWidth),
        ]

        if context.environment.dynamicTypeSize != .large {
            userScripts.append(.dynamicTypeSize)
        }

        userScripts
            .filter(\.isEnabled)
            .map { $0.toUserScript() }
            .forEach(config.userContentController.addUserScript)

        context.coordinator.setupRecovery(for: webView)
        context.environment.webViewPrintingRegistrar.register(webView: webView)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.receivedBodyDifferentFromBefore(latest: body) {
            schemeHandler.updateImagePolicy(with: body.imagePolicy)
            loadHTML(in: webView)
        }
        webView.overrideUserInterfaceStyle = context.environment.forceLightModeInMessageBody ? .light : .unspecified
        webView.isHidden = context.environment.orientationChangeInProgress
        context.coordinator.urlOpener = context.environment.openURL
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeAllScriptMessageHandlers()
    }

    func loadHTML(in webView: WKWebView) {
        let scaleFactor = currentFontScaleFactor()

        let style = """
            <style>
                @media not print {
                    html, body {
                        /* Android is currently testing this, we should probably upstream it to Rust once they approve */
                        height: auto !important;
                    }

                    table {
                        /* This does not make sense on mobile */
                        float: none;
                    }

                    body {
                        /* Dynamic type size */
                        --dts-scale-factor: \(scaleFactor * 100)%;
                    }
                }

                @media print {
                    body {
                        --dts-scale-factor: 100%;
                    }
                }
            </style>
            """
        let fixedBody = body.rawBody.replacingOccurrences(of: "</head>", with: "\(style)</head>")

        webView.loadHTMLString(fixedBody, baseURL: nil)
    }

    private func currentFontScaleFactor() -> CGFloat {
        let unscaledTraits = UITraitCollection(preferredContentSizeCategory: .large)
        let unscaledFont = UIFont.preferredFont(forTextStyle: .body, compatibleWith: unscaledTraits)
        let scaledFont = UIFont.preferredFont(forTextStyle: .body)
        return scaledFont.pointSize / unscaledFont.pointSize
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

extension MessageBodyReaderView {
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
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
            switch HandlerName(rawValue: scriptMessage.name) {
            case .consoleLog:
                AppLogger.log(message: "\(scriptMessage.body)", category: .webView)
            case .heightChanged:
                Task { @MainActor in
                    let scriptOutput = scriptMessage.body as! CGFloat

                    if shouldUpdateContentHeight(proposedNewHeight: scriptOutput) {
                        parent.bodyContentHeight = scriptOutput
                    }
                }
            case .none:
                fatalError()
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
            if previouslyReceivedBody == body {
                return false
            } else {
                previouslyReceivedBody = body
                return true
            }
        }

        private func shouldUpdateContentHeight(proposedNewHeight: CGFloat) -> Bool {
            let currentHeight = parent.bodyContentHeight

            if currentHeight > 0 {
                let isAtLeastOnePercentDifference = abs(proposedNewHeight - currentHeight) / currentHeight >= 0.01
                return isAtLeastOnePercentDifference
            } else {
                return true
            }
        }

        func webView(
            _ webView: WKWebView,
            contextMenuConfigurationFor elementInfo: WKContextMenuElementInfo
        ) async -> UIContextMenuConfiguration? {
            let configurationWithoutPreview = UIContextMenuConfiguration(
                actionProvider: { menuElements in
                    UIMenu(title: .empty, children: menuElements)
                }
            )

            return parent.confirmLink ? configurationWithoutPreview : nil
        }
    }
}

@MainActor
private struct AppScript {
    let source: String
    let isEnabled: Bool

    init(source: String, isEnabled: Bool = true) {
        self.source = source
        self.isEnabled = isEnabled
    }

    func toUserScript() -> WKUserScript {
        WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
}

extension AppScript {
    fileprivate static func adjustLayoutAndObserveHeight(viewWidth: CGFloat) -> Self {
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
                if (!metaWidth) {
                    metaWidth = document.createElement('meta');
                    metaWidth.name = 'viewport';
                    document.head.appendChild(metaWidth);
                }
                metaWidth.content = "width=device-width, initial-scale=" + ratio + ", maximum-scale=3.0, user-scalable=yes";
            }

            function appendBottomMarker() {
                const bottomMarker = document.createElement('div');
                bottomMarker.id = 'proton-bottom-marker';
                bottomMarker.style = 'display: initial !important;';
                return document.body.appendChild(bottomMarker);
            }

            function startSendingHeightToSwiftUI(bottomMarker, ratio) {
                const observer = new ResizeObserver(() => {
                    const bottomMarkerRect = bottomMarker.getBoundingClientRect();
                    const bottomPadding = Number.parseFloat(window.getComputedStyle(document.documentElement, null).paddingBottom);
                    const bottommostPoint = window.scrollY + bottomMarkerRect.top + bottomMarkerRect.height + bottomPadding;
                    const height = bottommostPoint * ratio;
                    window.webkit.messageHandlers.\(HandlerName.heightChanged.rawValue).postMessage(height);
                });

                observer.observe(document.body);
            }

            executeOnceContentIsLaidOut(() => {
                const ratio = document.body.offsetWidth / document.body.scrollWidth;
                setViewportInitialScale(ratio);
                const bottomMarker = appendBottomMarker();
                startSendingHeightToSwiftUI(bottomMarker, ratio);
            });
            """

        return .init(source: source)
    }

    /// A message can theoretically have an empty <body>. In such case the observed body height will be 0, and the loading spinner would be shown indefinitely.
    fileprivate static let handleEmptyBody = Self(
        source: """
            if (document.body.childNodes.length == 0) {
                var spacer = document.createElement('br');
                document.body.appendChild(spacer);
            }
            """
    )

    fileprivate static let redirectConsoleLogToAppLogger = Self(
        source: """
            var console = {};

            console.log = function(message) {
                window.webkit.messageHandlers.\(HandlerName.consoleLog.rawValue).postMessage(message)
            };

            console.error = function(message) {
                window.webkit.messageHandlers.\(HandlerName.consoleLog.rawValue).postMessage(message)
            };
            """,
        isEnabled: WKWebView.inspectabilityEnabled
    )

    fileprivate static let dynamicTypeSize: Self = {
        .loadScript(named: "DynamicTypeSize")
    }()

    fileprivate static let stripUnwantedStyleProperties: Self = {
        .loadScript(named: "StripUnwantedStyleProperties")
    }()

    fileprivate static let stylePropertyCoding: Self = {
        .loadScript(named: "StylePropertyCoding")
    }()

    private static func loadScript(named resourceName: String) -> Self {
        let scriptURL = Bundle.main.url(forResource: resourceName, withExtension: "js")!
        let source = try! String(contentsOf: scriptURL, encoding: .utf8)
        return .init(source: source)
    }
}

private enum HandlerName: String, CaseIterable {
    case consoleLog
    case heightChanged
}
