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

import ProtonCore_DataModel
import ProtonCore_UIFoundations
import WebKit

/// Contains HTML to be loaded into WebView and appropriate CSP
struct WebContents: Equatable {
    let body: String
    let remoteContentMode: RemoteContentPolicy
    var renderStyle: MessageRenderStyle
    let supplementCSS: String?

    var bodyForJS: String {
        return self.body.escaped
    }

    init(body: String,
         remoteContentMode: RemoteContentPolicy,
         renderStyle: MessageRenderStyle = .dark,
         supplementCSS: String? = nil) {
        if UserInfo.isEncryptedSearchEnabledFreeUsers || UserInfo.isEncryptedSearchEnabledPaidUsers {
            var highlightedBody: String = body
            let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
            if let userID = usersManager.firstUser?.userInfo.userId {
                let expectedESStates: [EncryptedSearchService.EncryptedSearchIndexState] = [.partial, .complete]
                if expectedESStates.contains(EncryptedSearchService.shared.getESState(userID: userID)) {
                    highlightedBody = EncryptedSearchService.shared.highlightKeyWords(bodyAsHtml: body)
                }
            }

            // \u00A0 is white space that will break dompurify
            self.body = highlightedBody.preg_replace("\u{00A0}", replaceto: " ")
        } else {
            // \u00A0 is white space that will break dompurify
            self.body = body.preg_replace("\u{00A0}", replaceto: " ")
        }
        self.remoteContentMode = remoteContentMode
        self.renderStyle = renderStyle
        self.supplementCSS = supplementCSS
    }

    var contentSecurityPolicy: String {
        return self.remoteContentMode.cspRaw
    }

    enum RemoteContentPolicy: Int {
        case allowed, disallowed, lockdown

        var cspRaw: String {
            switch self {
            case .lockdown:
                return "default-src 'none'; style-src 'self' 'unsafe-inline';"

            case .disallowed: // this cuts off all remote content
                // swiftlint:disable line_length
                return "default-src 'none'; style-src 'self' 'unsafe-inline'; img-src 'unsafe-inline' data: blob:; script-src 'none';"

            case .allowed: // this cuts off only scripts and connections
                // swiftlint:disable line_length
                return "default-src 'self'; connect-src 'self' blob:; style-src 'self' 'unsafe-inline'; img-src http: https: data: blob: cid:; script-src 'none';"
            }
        }
    }

    enum EmbeddedContentPolicy {
        case disallowed
        case allowed
    }

    static var css: String = {
        guard let bundle = Bundle.main.path(forResource: "content", ofType: "css"),
              var content = try? String(contentsOfFile: bundle, encoding: .utf8) else {
            return .empty
        }

        var backgroundColor = ColorProvider.BackgroundNorm.toHex()
        var textColor = ColorProvider.TextNorm.toHex()
        var brandColor = ColorProvider.BrandNorm.toHex()

        var darkBackgroundColor = ColorProvider.BackgroundNorm.toHex()
        var darkTextColor = ColorProvider.TextNorm.toHex()
        var darkBrandColor = ColorProvider.BrandNorm.toHex()

        if #available(iOS 13.0, *) {
            let trait = UITraitCollection(userInterfaceStyle: .dark)
            darkBackgroundColor = ColorProvider.BackgroundNorm.resolvedColor(with: trait).toHex()
            darkTextColor = ColorProvider.TextNorm.resolvedColor(with: trait).toHex()
            darkBrandColor = ColorProvider.BrandNorm.resolvedColor(with: trait).toHex()

            let lightTrait = UITraitCollection(userInterfaceStyle: .light)
            backgroundColor = ColorProvider.BackgroundNorm.resolvedColor(with: lightTrait).toHex()
            textColor = ColorProvider.TextNorm.resolvedColor(with: lightTrait).toHex()
            brandColor = ColorProvider.BrandNorm.resolvedColor(with: lightTrait).toHex()
        }

        content = content.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "{{proton-background-color}}", with: backgroundColor)
            .replacingOccurrences(of: "{{proton-text-color}}", with: textColor)
            .replacingOccurrences(of: "{{proton-brand-color}}", with: brandColor)
            .replacingOccurrences(of: "{{proton-background-color-dark}}", with: darkBackgroundColor)
            .replacingOccurrences(of: "{{proton-text-color-dark}}", with: darkTextColor)
            .replacingOccurrences(of: "{{proton-brand-color-dark}}", with: darkBrandColor)
        return content
    }()

    static var cssLightModeOnly: String = {
        guard let bundle = Bundle.main.path(forResource: "content_light", ofType: "css"),
              var content = try? String(contentsOfFile: bundle, encoding: .utf8) else {
                  return .empty
              }

        let brandColor: String
        if #available(iOS 13.0, *) {
            brandColor = ColorProvider.BrandNorm.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).toHex()
        } else {
            brandColor = ColorProvider.BrandNorm.toHex()
        }
        content = content.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "{{proton-brand-color}}", with: brandColor)
        return content
    }()

    // swiftlint:disable force_try force_unwrapping
    static var domPurifyConstructor: WKUserScript = {
        let raw = try! String(contentsOf: Bundle.main.url(forResource: "purify.min", withExtension: "js")!)
        return WKUserScript(source: raw, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }()
}
