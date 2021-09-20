// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import SwiftSoup

extension String {
    private static let quoteElements: [String] = [
        ".protonmail_quote",
        ".gmail_quote",
        ".yahoo_quoted",
        ".gmail_extra",
        ".zmail_extra", // zoho
        ".moz-cite-prefix",
        "#isForwardContent",
        "#isReplyContent",
        "#mailcontent:not(table)",
        "#origbody",
        "#reply139content",
        "#oriMsgHtmlSeperator",
        "blockquote[type=\"cite\"]",
        "[name=\"quote\"]" // gmx
    ]
    func body(strippedFromQuotes: Bool) -> String {
        do {
            let strippedHTML: String
            let fullHTMLDocument = try SwiftSoup.parse(self)
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
