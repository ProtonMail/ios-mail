//
//  HTMLSecureLoader.swift
//  Proton Mail - Created on 06/01/2019.
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
import WebKit

class RenderedContents: NSObject {
    @objc internal dynamic var preheight: CGFloat = 0.1
    @objc internal dynamic var height: CGFloat = 0.1

    internal func invalidate() {
        self.preheight = 0.1
        self.height = 0.1
    }

    internal var isValid: Bool {
        return self.height != 0.1
    }
}

protocol WebContentsSecureLoader {
    var renderedContents: RenderedContents { get }
    func load(contents: WebContents, in webView: WKWebView)
    func inject(into config: WKWebViewConfiguration)
    func observeHeight(_ callBack: @escaping ((CGFloat) -> Void))
}
extension WebContentsSecureLoader {
    func eject(from config: WKWebViewConfiguration) {
        config.userContentController.removeScriptMessageHandler(forName: "loaded")
    }
}

enum DomPurifyConfig {
    case `default`, protonizer

    var value: String {
        switch self {
        case .default:
            return """
            {
            ALLOWED_URI_REGEXP: /^(?:(?:(?:f|ht)tps?|mailto|tel|callto|cid|blob|xmpp|data):|[^a-z]|[a-z+.\\-]+(?:[^a-z+.\\-:]|$))/i,
            ADD_TAGS: ['proton-src', 'base'],
            ADD_ATTR: ['target', 'proton-src'],
            FORBID_TAGS: ['body', 'style', 'input', 'form', 'video', 'audio'],
            FORBID_ATTR: ['srcset']
            }
            """.replacingOccurrences(of: "\n", with: "")
        case .protonizer:
            return """
            {
            FORBID_TAGS: ['input', 'form'], // Override defaults to allow style (will be processed by juice afterward)
            FORBID_ATTR: {},
            ADD_ATTR: ['target', 'proton-data-src', 'proton-src', 'proton-srcset', 'proton-background', 'proton-poster', 'proton-xlink:href', 'proton-href'],
            WHOLE_DOCUMENT: true,
            RETURN_DOM: true
            }
            """
        }
    }
}
