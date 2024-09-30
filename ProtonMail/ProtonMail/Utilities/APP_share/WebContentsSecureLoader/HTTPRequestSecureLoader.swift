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
import ProtonCoreUIFoundations
import WebKit

/// Loads web content into WKWebView by means of load(_:) and inner URLRequest method. In order to prevent resources prefetching, loading happens in a number of stages:
/// 1. webView gets a WKContentRuleList restricting any loads other than current url and a custom scheme handler
/// 2. construct URLRequest for that url and ask webView to start loading
/// 3. webView asks custom scheme handler to handle the request, we create response with required data and required CSP in HTTP headers, return it to webView
/// 4. DOMPurifier sanitizes contents, once sanitization is complete, css is injected into required contents
/// 5. webView switches off content rule list and reloads sanitized contents body
///

protocol HTTPRequestSecureLoaderDelegate: AnyObject {
    func showSkeletonView()
    func hideSkeletonView()
}

final class HTTPRequestSecureLoader: NSObject, WKScriptMessageHandler {
    private var heightChanged: ((CGFloat) -> Void)?
    /// Callback to update the webview is scrollable when the rendering is done.
    private var contentShouldBeScrollableByDefaultChanged: ((Bool) -> Void)?

    private weak var webView: WKWebView?
    private var blockRules: WKContentRuleList?
    weak var delegate: HTTPRequestSecureLoaderDelegate?

    enum ProtonScheme: String {
        case http = "proton-http"
        case https = "proton-https"
        case noProtocol = "proton-"
        case pmCache = "proton-pm-cache"
    }

    static let loopbackScheme = "pm-incoming-mail"
    static let imageCacheScheme = "pm-cache"

    private let dynamicFontSizeMessageHandler = DynamicFontSizeMessageHandler()
    private let schemeHandler: SecureLoaderSchemeHandler

    init(schemeHandler: SecureLoaderSchemeHandler) {
        self.schemeHandler = schemeHandler
    }

    /// - Returns: start to load content
    func load(contents: WebContents, in webView: WKWebView) -> Bool {
        guard webView.frame.width > 0 else {
            // Sometimes size of webView is wrong, viewPort ratio will be wrong when loading under this condition
            return false
        }
        if contents.body.isEmpty {
            delegate?.showSkeletonView()
        }

        self.webView?.stopLoading()
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
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "ContentBlockingRules-\(urlString)", encodedContentRuleList: blockRules) { contentRuleList, error in
            guard error == nil, let compiledRule = contentRuleList else {
                assert(error == nil, "Error compiling content blocker rules: \(error!.localizedDescription)")
                return
            }
            guard let latestRequest = self.schemeHandler.latestRequest,
                  compiledRule.identifier.hasSuffix(latestRequest) else { return }
            self.blockRules = compiledRule
            self.prepareRendering(contents, into: webView.configuration)
            webView.load(request)
        }
        return true
    }

    func observeHeight(_ callBack: @escaping ((CGFloat) -> Void)) {
        self.heightChanged = callBack
    }

    func observeContentShouldBeScrollableByDefault(_ callBack: @escaping ((Bool) -> Void)) {
        self.contentShouldBeScrollableByDefaultChanged = callBack
    }

    private func generateCSS(from contents: WebContents) -> String {
        var css: String
        switch contents.renderStyle {
        case .lightOnly:
            css = WebContents.cssLightModeOnly
        case .dark:
            css = WebContents.css
            if let supplementCSS = contents.supplementCSS {
                css += supplementCSS
            } else {
                // means this message doesn't support dark mode style
                css = WebContents.cssLightModeOnly
            }
        }
        let smallestSupportedWidth: CGFloat = 375
        var screenWidth = webView?.window?.screen.bounds.width ?? smallestSupportedWidth
        let paddingOfCell: CGFloat = 8
        screenWidth = screenWidth - 2 * paddingOfCell
        return css.replacingOccurrences(of: "{{screen-width}}", with: "\(Int(screenWidth))px")
    }

    private func generateContentSanitizationJSCode(from contents: WebContents) -> String {
        var jsCodeBlock = """
            // Get original message body string
            var dirty = document.documentElement.outerHTML.toString();

            var clean0 = DOMPurify.sanitize(dirty, \(DomPurifyConfig.imageCache.value));
        """
        switch contents.contentLoadingType {
        case .skipProxy:
            jsCodeBlock += """
                // Sanitize message head
                let protonizer = DOMPurify.sanitize(dirty, \(DomPurifyConfig.protonizer.value));
                let messageHead = protonizer.querySelector('head').innerHTML.trim()

                // Sanitize message content
                var clean1 = DOMPurify.sanitize(clean0, \(DomPurifyConfig.default.value));
            """
        case .proxy, .skipProxyButAskForTrackerInfo:
            /* 
             `escapeForbiddenStyleInElement` function is used to escape the forbidden element in the `STYLE` tag.
             It will add `proton-` prefix to the tag e.g. `background:image-set` will become `background:proton-image-set`, `background:url(XXX` will become `background:url(proton-XXX`.

             `beforeSanitizeElements` function will add `proton-` to the attribute of the specific element e.g. `https` will become `proton-https`.
            */
            jsCodeBlock += """
                // Sanitize message head
                DOMPurify.addHook('beforeSanitizeElements', escapeForbiddenStyleInElement);
                let protonizer = DOMPurify.sanitize(dirty, \(DomPurifyConfig.protonizer.value));
                DOMPurify.removeHook('beforeSanitizeElements');
                let messageHead = protonizer.querySelector('head').innerHTML.trim()

                // Sanitize message content
                DOMPurify.addHook('beforeSanitizeElements', beforeSanitizeElements);
                var clean1 = DOMPurify.sanitize(clean0, \(DomPurifyConfig.default.value));
                DOMPurify.removeHook('beforeSanitizeElements');
            """
        }
        jsCodeBlock += """
            // Generate HTTP DOM to be used to show in the webView
            var clean2 = DOMPurify.sanitize(clean1, \(DomPurifyConfig.raw.value));
            document.documentElement.replaceWith(clean2);
        """
        return jsCodeBlock
    }

    private func prepareRendering(_ contents: WebContents, into config: WKWebViewConfiguration) {
        schemeHandler.contents = contents

        let css = generateCSS(from: contents)
        let contentLoadingCodeBlock = generateContentSanitizationJSCode(from: contents)

        var removeCSSImportantByJS = ""
        if !(contents.supplementCSS?.isEmpty ?? true) {
            removeCSSImportantByJS = """
                // Remove color related `!important`
                let styles = document.head.querySelectorAll('style')
                for (var i = 0, max = styles.length; i < max; i++) {
                    let style = styles[i]
                    if (!style.textContent.includes('!important')) { continue }
                    let css = style.textContent.replace(/((color|bgcolor|background-color|background|border):.*?)\\s{0,}(!important)?;/g, "$1;")
                    document.head.querySelectorAll('style')[i].textContent = css;
                }

                let targetDOMs = document.querySelectorAll('*:not(html):not(head):not(script):not(meta):not(title)')
                for (var i = 0, max = targetDOMs.length; i < max; i++) {
                    let dom = targetDOMs[i]
                    if (!dom.style.cssText.includes('!important')) { continue }
                    let css = dom.getAttribute('style').replace(/((color|bgcolor|background-color|background|border):.*?)\\s{0,}(!important)?;/g, "$1;")
                    dom.setAttribute('style', css);
                }
            """
        }

        let sanitizeContentJSCode = """
        \(removeCSSImportantByJS)
        \(contentLoadingCodeBlock)
        var style = document.createElement('style');
        style.type = 'text/css';
        style.appendChild(document.createTextNode(`\(css)`));
        document.getElementsByTagName('head')[0].appendChild(style);

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

        let sanitize = WKUserScript(source: sanitizeContentJSCode + message, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.removeAllUserScripts()
        #if DEBUG
        let loggerCode = """
            // Print log on console
            var console = {};
            console.log = function(message){window.webkit.messageHandlers['logger'].postMessage(message)};
        """
        let loggerScript = WKUserScript(source: loggerCode, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(loggerScript)
        #endif
        config.userContentController.addUserScript(WebContents.domPurifyConstructor)
        config.userContentController.addUserScript(WebContents.escapeJS)
        config.userContentController.addUserScript(WebContents.loaderJS)
        config.userContentController.addUserScript(sanitize)
        #if DEBUG
        config.userContentController.removeScriptMessageHandler(forName: "logger")
        config.userContentController.add(self, name: "logger")
        #endif

        config.userContentController.removeScriptMessageHandler(forName: "scaledValue", contentWorld: .page)
        config.userContentController.addScriptMessageHandler(dynamicFontSizeMessageHandler, contentWorld: .page, name: "scaledValue")

        config.userContentController.removeAllContentRuleLists()
        config.userContentController.add(self.blockRules!)
    }

    private func handleConsoleLogFromJS(message: WKScriptMessage) {
        guard let body = message.body as? String, message.name == "logger" else {
            assertionFailure("Unexpected message sent from JS")
            return
        }
        SystemLogger.log(message: "WebView log:\(body)", category: .webView)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any] else {
            handleConsoleLogFromJS(message: message)
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
                    if (result !== null) {
                        document.body.innerHTML = result[0];
                    }
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

                    window.webkit.messageHandlers.loaded.postMessage({'height': height, 'refHeight': refHeight, 'contentShouldBeScrollableByDefault': ratio < 1});
            """

            userContentController.addUserScript(WebContents.blockQuoteJS)
            let sanitize = WKUserScript(source: message, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            userContentController.addUserScript(sanitize)
            userContentController.addUserScript(WebContents.dynamicFontSize)

            let urlString = (UUID().uuidString + ".proton").lowercased()
            let url = URL(string: HTTPRequestSecureLoader.loopbackScheme + "://" + urlString)!
            let request = URLRequest(url: url)
            let data = sanitized.data(using: .unicode)
            schemeHandler.loopbacks[url] = data

            self.webView?.load(request)
            self.delegate?.hideSkeletonView()
        }
        if let height = dict["height"] as? Double {
            let refHeight = (dict["refHeight"] as? CGFloat) ?? CGFloat(height)
            let res = refHeight > 32 ? refHeight : CGFloat(height)
            self.heightChanged?(res)
        }
        if let contentShouldBeScrollableByDefault = dict["contentShouldBeScrollableByDefault"] as? Bool {
            // The contentShouldBeScrollableByDefault means that the webview should be scrollable after rendering by default.
            // It also means that the content width can not be fully displayed on the device.
            // We will allow the user to scroll the content by default.
            contentShouldBeScrollableByDefaultChanged?(contentShouldBeScrollableByDefault)
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

    func eject(from config: WKWebViewConfiguration) {
        config.userContentController.removeScriptMessageHandler(forName: "loaded")
#if DEBUG
        config.userContentController.removeScriptMessageHandler(forName: "logger")
#endif
    }
}
