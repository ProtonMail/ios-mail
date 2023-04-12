// Copyright (c) 2021 Proton AG
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

import Foundation
import SwiftSoup

// swiftlint:disable:file_name
extension String {
    static let quoteElements: [String] = [
        ".protonmail_quote", // Proton Mail
        // Gmail creates both div.gmail_quote and blockquote.gmail_quote. The div
        // version marks text but does not cause indentation, but both should be
        // considered quoted text.
        ".gmail_quote", // Gmail
        "div.gmail_extra", // Gmail
        "div[id*=yahoo_quoted]", // Yahoo Mail
        "blockquote.iosymail", // Yahoo iOS Mail
        ".tutanota_quote", // Tutanota Mail
        ".zmail_extra", // Zoho
        ".skiff_quote", // Skiff Mail
        "hr[id=replySplit]",
        ".moz-cite-prefix",
        "div[id=isForwardContent]",
        "blockquote[id=isReplyContent]",
        "div[id=mailcontent]",
        "div[id=origbody]",
        "div[id=reply139content]",
        "blockquote[id=oriMsgHtmlSeperator]",
        "blockquote[type=\"cite\"]",
        "[name=\"quote\"]", // gmx
        ".moz-forward-container"
    ]

    func body(strippedFromQuotes: Bool) -> String {
        do {
            let strippedHTML: String
            let fullHTMLDocument = try SwiftSoup.parse(self)
            fullHTMLDocument.outputSettings().prettyPrint(pretty: false)
            guard strippedFromQuotes else {
                return try fullHTMLDocument.html()
            }
            var quoteElements: [Elements] = []
            for quoteElement in Self.quoteElements {
                if let elements = try? fullHTMLDocument.select(quoteElement) {
                    quoteElements.append(elements)
                }
            }
            for quoteElement in quoteElements {
                _ = try? quoteElement.remove()
            }
            strippedHTML = try fullHTMLDocument.html()
            return strippedHTML
        } catch {
            return self
        }
    }
}
