//
//  HTTPRequestSecureLoader.swift
//  Proton Mail - Created on 15/01/2019.
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
import ProtonCore_UIFoundations
import WebKit

/// Loads web content into WKWebView by means of load(_:) and inner URLRequest method. In order to prevent resources prefetching, loading happens in a number of stages:
/// 1. webView gets a WKContentRuleList restricting any loads other than current url and a custom scheme handler
/// 2. construct URLRequest for that url and ask webView to start loading
/// 3. webView asks custom scheme handler to handle the request, we create response with required data and required CSP in HTTP headers, return it to webView
/// 4. DOMPurifier sanitizes contents, once sanitization is complete, css is injected into required contents
/// 5. webView switches off content rule list and reloads sanitized contents body
///
/// Why this is good:
/// - object-oriented approach to CSP and blocking of early resources loading
///
/// Why that is not perfect:
/// - WKContentRuleList and WKURLSchemeHandler are not supported until iOS 11
///
class HTTPRequestSecureLoader: NSObject, WebContentsSecureLoader, WKScriptMessageHandler {
    internal let renderedContents = RenderedContents()
    private var heightChanged: ((CGFloat) -> Void)?

    private weak var webView: WKWebView?
    private var blockRules: WKContentRuleList?

    enum ProtonScheme: String {
        case http = "proton-http"
        case https = "proton-https"
        case noProtocol = "proton-"
        case pmCache = "proton-pm-cache"
    }

    static let loopbackScheme = "pm-incoming-mail"
    static let imageCacheScheme = "pm-cache"

    private let schemeHandler: SecureLoaderSchemeHandler

    init(schemeHandler: SecureLoaderSchemeHandler) {
        self.schemeHandler = schemeHandler
    }

    func load(contents: WebContents, in webView: WKWebView) {
        addSpinnerIfNeeded(to: webView)

        self.webView?.stopLoading()
        self.renderedContents.invalidate()
        self.webView?.configuration.userContentController.removeAllUserScripts()
        self.webView?.loadHTMLString("", baseURL: URL(string: "about:blank")!)

        self.webView = webView

        switch contents.renderStyle {
        case .lightOnly:
            self.webView?.backgroundColor = .white
        case .dark:
            self.webView?.backgroundColor = ColorProvider.BackgroundNorm
        }

        let urlString = (UUID().uuidString + ".proton").lowercased()
        let url = URL(string: HTTPRequestSecureLoader.loopbackScheme + "://" + urlString)!
        let request = URLRequest(url: url)
        let data = contents.body.data(using: .unicode)
        schemeHandler.latestRequest = urlString
        schemeHandler.loopbacks[url] = data
        schemeHandler.contents = contents

        let builder = ContentBlockRuleBuilder()
            .add(
                rule: ContentBlockRuleBuilder.Rule()
                    .addTrigger(key: .urlFilter, value: ".*")
                    .addAction(key: .type, value: .block)
            )
            .add(
                rule: ContentBlockRuleBuilder.Rule()
                    .addTrigger(key: .urlFilter, value: urlString)
                    .addAction(key: .type, value: .ignorePreviousRules)
            )
        let blockRules = builder.export() ?? ""
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "ContentBlockingRules", encodedContentRuleList: blockRules) { contentRuleList, error in
            guard error == nil, let compiledRule = contentRuleList else {
                assert(error == nil, "Error compiling content blocker rules: \(error!.localizedDescription)")
                return
            }
            self.blockRules = compiledRule
            self.prepareRendering(contents, into: webView.configuration)
            webView.load(request)
        }
    }

    func observeHeight(_ callBack: @escaping ((CGFloat) -> Void)) {
        self.heightChanged = callBack
    }

    private func prepareRendering(_ contents: WebContents, into config: WKWebViewConfiguration) {
        let smallestSupportedWidth: CGFloat = 375
        var screenWidth = webView?.window?.screen.bounds.width ?? smallestSupportedWidth
        let paddingOfCell: CGFloat = 8
        screenWidth = screenWidth - 2 * paddingOfCell
        schemeHandler.contents = contents
        var css: String
        switch contents.renderStyle {
        case .lightOnly:
            css = WebContents.cssLightModeOnly
        case .dark:
            css = WebContents.css
            if let supplementCSS = contents.supplementCSS,
               !supplementCSS.isEmpty {
                css += supplementCSS
            } else {
                // means this message doesn't support dark mode style
                css = WebContents.cssLightModeOnly
            }
        }

        let loadingType = contents.contentLoadingType
        var imageProxyCodeBlock: String = .empty
        switch loadingType {
        case .direct:
            imageProxyCodeBlock = """
            var clean1 = DOMPurify.sanitize(clean0, \(DomPurifyConfig.default.value));
            """
        case .proxy, .proxyDryRun, .none:
            imageProxyCodeBlock = """
            DOMPurify.addHook('beforeSanitizeElements', beforeSanitizeElements);
            var clean1 = DOMPurify.sanitize(clean0, \(DomPurifyConfig.default.value));
            DOMPurify.removeHook('beforeSanitizeElements');
            """
        }

        css = css.replacingOccurrences(of: "{{screen-width}}", with: "\(Int(screenWidth))px")
        let sanitizeRaw = """
        var dirty = document.documentElement.outerHTML.toString();
        let protonizer = DOMPurify.sanitize(dirty, \(DomPurifyConfig.protonizer.value));
        let messageHead = protonizer.querySelector('head').innerHTML.trim()
        var clean0 = DOMPurify.sanitize(dirty, \(DomPurifyConfig.imageCache.value));
        \(imageProxyCodeBlock)
        var clean2 = DOMPurify.sanitize(clean1, { WHOLE_DOCUMENT: true, RETURN_DOM: true});
        document.documentElement.replaceWith(clean2);

        var style = document.createElement('style');
        style.type = 'text/css';
        style.appendChild(document.createTextNode(`\(css)`));

        let wrapper = document.createElement('div');
        wrapper.innerHTML = messageHead;
        wrapper.append(style);
        Array.from(wrapper.children).forEach(item => document.getElementsByTagName('head')[0].appendChild(item))

        var metaWidth = document.createElement('meta');
        metaWidth.name = "viewport";
        metaWidth.content = "width=device-width";
        var rects = document.body.getBoundingClientRect();
        var ratio = document.body.offsetWidth/document.body.scrollWidth;

        document.getElementsByTagName('head')[0].appendChild(metaWidth);
        """

        let message = """
        var items = document.body.getElementsByTagName('*');
        for (var i = items.length; i--;) {
            if (items[i].style.getPropertyValue("height") == "100%") {
                items[i].style.height = "auto";
            };
        };
        window.webkit.messageHandlers.loaded.postMessage({'preheight': ratio * rects.height, 'clearBody': document.documentElement.outerHTML.toString()});
        """

        let sanitize = WKUserScript(source: sanitizeRaw + message, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.removeAllUserScripts()
        config.userContentController.addUserScript(WebContents.domPurifyConstructor)
        config.userContentController.addUserScript(WebContents.escapeJS)
        config.userContentController.addUserScript(WebContents.loaderJS)
        config.userContentController.addUserScript(sanitize)

        config.userContentController.add(self.blockRules!)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any] else {
            assertionFailure("Unexpected message sent from JS")
            return
        }

        guard schemeHandler.latestRequest == nil else {
            // There is a newer request, anything related to old request should be stoped
            return
        }

        if let sanitized = dict["clearBody"] as? String {
            userContentController.removeAllContentRuleLists()
            userContentController.removeAllUserScripts()

            var displayHistoryCodeBlock: String = .empty
            if schemeHandler.contents?.messageDisplayMode == .collapsed {
                displayHistoryCodeBlock = """
                    // `searchBlockQuote` function returns an array that contains two strings.
                    // You can find the function in `Blockquote.js` file.
                    // The first string is the body that has the history removed.
                    // The second string is the body of the removed history.
                    let result = searchBlockQuote(document);

                    // Hide the history of the message.
                    document.body.innerHTML = result[0];
                """
            }

            let message = """
                    \(displayHistoryCodeBlock)

                    var metaWidth = document.querySelector('meta[name="viewport"]');
                    metaWidth.content = "width=device-width";
                    var ratio = document.body.offsetWidth/document.body.scrollWidth;
                    if (ratio < 1) {
                        metaWidth.content = metaWidth.content + ", initial-scale=" + ratio + ", maximum-scale=3.0, user-scalable=yes";
                    } else {
                        ratio = 1;
                    };
                    let body = document.body;
                    let height = ratio * document.body.scrollHeight;
                    var refHeight = height;
                    let lowest = 32;
                    Array.from(body.children).forEach(element => {
                        let bottom = element.getBoundingClientRect().bottom + 32;
                        if (bottom > lowest) {
                            lowest = bottom;
                            refHeight = bottom * ratio;
                        }
                    });

                    window.webkit.messageHandlers.loaded.postMessage({'height': height, 'refHeight': refHeight});
            """

            userContentController.addUserScript(WebContents.blockQuoteJS)
            let sanitize = WKUserScript(source: message, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            userContentController.addUserScript(sanitize)

            let urlString = (UUID().uuidString + ".proton").lowercased()
            let url = URL(string: HTTPRequestSecureLoader.loopbackScheme + "://" + urlString)!
            let request = URLRequest(url: url)
            let data = sanitized.data(using: .unicode)
            schemeHandler.loopbacks[url] = data

            self.webView?.load(request)

            removeAllSpinners()
        }
        if let preheight = dict["preheight"] as? Double {
            self.renderedContents.preheight = CGFloat(preheight)
        }
        if let height = dict["height"] as? Double {
            self.renderedContents.height = CGFloat(height)
            let refHeight = (dict["refHeight"] as? CGFloat) ?? CGFloat(height)
            let res = refHeight > 32 ? refHeight : CGFloat(height)
            self.heightChanged?(res)
        }
    }

    func inject(into config: WKWebViewConfiguration) {
        config.userContentController.add(self, name: "loaded")
        config.setURLSchemeHandler(
            schemeHandler,
            forURLScheme: HTTPRequestSecureLoader.imageCacheScheme
        )
        config.setURLSchemeHandler(
            schemeHandler,
            forURLScheme: HTTPRequestSecureLoader.loopbackScheme
        )
        config.setURLSchemeHandler(
            schemeHandler,
            forURLScheme: ProtonScheme.http.rawValue
        )
        config.setURLSchemeHandler(
            schemeHandler,
            forURLScheme: ProtonScheme.https.rawValue
        )
        config.setURLSchemeHandler(
            schemeHandler,
            forURLScheme: ProtonScheme.noProtocol.rawValue
        )
        config.setURLSchemeHandler(
            schemeHandler,
            forURLScheme: ProtonScheme.pmCache.rawValue
        )
    }

    private func addSpinnerIfNeeded(to webView: WKWebView) {
        guard webView.subviews.compactMap({ $0 as? UIActivityIndicatorView }).isEmpty else {
            return
        }
        let spinner = UIActivityIndicatorView()
        webView.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        [
            spinner.topAnchor.constraint(equalTo: webView.topAnchor, constant: 4),
            spinner.centerXAnchor.constraint(equalTo: webView.centerXAnchor)
        ].activate()
        spinner.startAnimating()
    }

    private func removeAllSpinners() {
        self.webView?.subviews.compactMap { $0 as? UIActivityIndicatorView }.forEach { view in
            view.stopAnimating()
            view.removeFromSuperview()
        }
    }
}
