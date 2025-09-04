// Copyright (c) 2025 Proton Technologies AG
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

struct HtmlSanitizer {

    /// Escapes characters that can trigger WebKit JS SyntaxError
    static func applyStringLiteralEscapingRules(html: String) -> String {
        // We use JSONEncoder as a trick to ensure all problematic
        // characters (quotes, backslashes, control chars) are properly escaped.
        let jsonEncodedText = try! JSONEncoder().encode(html)
        let sanitized = String(data: jsonEncodedText, encoding: .utf8)!
        return sanitized
    }

    static func removeStyleAttribute(html: String) -> String {
        let regex = try! NSRegularExpression(
            pattern: #"(?<![\w-])style\s*=\s*(?:"[^"]*"|'[^']*')"#,
            options: .caseInsensitive
        )
        let range = NSRange(location: 0, length: html.utf16.count)
        let sanitizedString = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "")
        return sanitizedString
    }
}
