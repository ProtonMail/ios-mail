//
//  WebContents.swift
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

import ProtonCore_UIFoundations
import WebKit

/// Contains HTML to be loaded into WebView and appropriate CSP
struct WebContents: Equatable {

    enum LoadingType {
        case direct
        case proxy
        case proxyDryRun
        case none
    }

    let body: String
    let remoteContentMode: RemoteContentPolicy
    var renderStyle: MessageRenderStyle
    let supplementCSS: String?
    let webImages: WebImageContents?
    let contentLoadingType: LoadingType
    let messageDisplayMode: MessageDisplayMode

    var bodyForJS: String {
        return self.body.escaped
    }

    init(body: String,
         remoteContentMode: RemoteContentPolicy,
         messageDisplayMode: MessageDisplayMode,
         contentLoadingType: LoadingType = .proxy,
         renderStyle: MessageRenderStyle = .dark,
         supplementCSS: String? = nil,
         webImages: WebImageContents? = nil) {
        // \u00A0 is white space that will break dompurify
        self.body = body.preg_replace("\u{00A0}", replaceto: " ")
        self.remoteContentMode = remoteContentMode
        self.messageDisplayMode = messageDisplayMode
        self.contentLoadingType = contentLoadingType
        self.renderStyle = renderStyle
        self.supplementCSS = supplementCSS
        self.webImages = webImages
    }

    var contentSecurityPolicy: String {
        return self.remoteContentMode.cspRaw
    }

    enum RemoteContentPolicy: Int {
        case allowed
        case disallowed
        case lockdown
        /// Allow content to be loaded by webview directly
        case allowedAll

        var cspRaw: String {
            let httpScheme = HTTPRequestSecureLoader.ProtonScheme.http.rawValue
            let httpsScheme = HTTPRequestSecureLoader.ProtonScheme.https.rawValue
            let noScheme = HTTPRequestSecureLoader.ProtonScheme.noProtocol.rawValue
            let pmCacheScheme = HTTPRequestSecureLoader.ProtonScheme.pmCache.rawValue

            let embeddedScheme = HTTPRequestSecureLoader.imageCacheScheme

            switch self {
            case .lockdown:
                return "default-src 'none'; style-src 'self' 'unsafe-inline';"
            case .disallowed: // this cuts off all remote content
                let valueToAdd = "\(httpScheme): \(httpsScheme): \(noScheme): \(embeddedScheme): \(pmCacheScheme):"
                return "default-src 'none'; style-src 'self' 'unsafe-inline'; img-src 'unsafe-inline' data: blob: \(valueToAdd); script-src 'none';"
            case .allowed: // this cuts off only scripts and connections
                let valueToAdd = "\(httpScheme): \(httpsScheme): \(noScheme): \(embeddedScheme): \(pmCacheScheme):"
                return "default-src 'self'; connect-src 'self' blob:; style-src 'self' 'unsafe-inline'; img-src data: blob: cid: \(valueToAdd); script-src 'none';"
            case .allowedAll: // allow all remote contents
                let valueToAdd = "\(httpScheme): \(httpsScheme): \(noScheme): \(embeddedScheme): \(pmCacheScheme):"
                return "default-src 'self'; connect-src 'self' blob:; style-src 'self' 'unsafe-inline'; img-src data: blob: cid: http: https: \(valueToAdd); script-src 'none';"
            }
        }
    }

    enum EmbeddedContentPolicy {
        case disallowed
        case allowed
    }

    static var css: String = {
        (try? ProtonCSS.viewer.content()) ?? .empty
    }()

    static var cssLightModeOnly: String = {
        (try? ProtonCSS.viewerLightOnly.content()) ?? .empty
    }()

    // swiftlint:disable force_try force_unwrapping
    static var domPurifyConstructor: WKUserScript = {
        let raw = try! String(contentsOf: Bundle.main.url(forResource: "purify.min", withExtension: "js")!)
        return WKUserScript(source: raw, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }()

    // swiftlint:disable force_try force_unwrapping
    static var escapeJS: WKUserScript = {
        let raw = try! String(contentsOf: Bundle.main.url(forResource: "Escape", withExtension: "js")!)
        return WKUserScript(source: raw, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }()

    // swiftlint:disable force_try force_unwrapping
    static var loaderJS: WKUserScript = {
        let raw = try! String(contentsOf: Bundle.main.url(forResource: "Loader", withExtension: "js")!)
        return WKUserScript(source: raw, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }()

    // swiftlint:disable force_try force_unwrapping
    static var blockQuoteJS: WKUserScript = {
        var raw = try! String(contentsOf: Bundle.main.url(forResource: "Blockquote", withExtension: "js")!)
        let blockQuoteSelectors = String.quoteElements
            .map { "\($0):not(:empty)" }
            .joined(separator: ",")
        raw = raw.replacingOccurrences(
            of: "{{BLOCKQUOTE_SELECTOR_VALUE}}",
            with: "'\(blockQuoteSelectors)'"
        )
        return WKUserScript(source: raw, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }()
}
