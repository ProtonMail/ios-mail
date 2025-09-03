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
@testable import InboxComposer
import proton_app_uniffi
import Testing

final class HtmlSanitizerTests {

    @Test(
        "removes style attribute correctly",
        arguments: [
            (
                "when empty html",
                "",
                ""
            ),
            (
                "when no style attributes",
                "<p>Hello</p>",
                "<p>Hello</p>"
            ),
            (
                "when single style attribute",
                "<p style=\"color:red;\">Hello</p>",
                "<p >Hello</p>"
            ),
            (
                "when multiple style attributes",
                "<div style=\"margin:10px;\"><span style=\"color:blue;\">Text</span></div>",
                "<div ><span >Text</span></div>"
            ),
            (
                "when style in uppercase",
                "<p STYLE=\"color:red;\">Hello</p>",
                "<p >Hello</p>"
            ),
            (
                "when more complex CSS",
                "<p style=\"color:red; font-size:14px; background:#fff;\">Hello</p>",
                "<p >Hello</p>"
            ),
            (
                "when multiple different attributes",
                "<p class=\"text\" style=\"color:red;\" id=\"p1\">Hello</p>",
                "<p class=\"text\"  id=\"p1\">Hello</p>"
            ),
            (
                "when attribute with style in its name, it keeps it",
                "<p data-style=\"foo:bar;\" style=\"color:red;\">Hello</p>",
                "<p data-style=\"foo:bar;\" >Hello</p>"
            ),
            (
                "when img tag has a style attribute",
                "<div style=\"background:red;\"><p>Here is an image: <img src=\"image.png\" style=\"width:100px; height:auto;\" alt=\"image\"></p></div>",
                "<div ><p>Here is an image: <img src=\"image.png\"  alt=\"image\"></p></div>"
            ),
        ])
    func removeStyleAttribute(context: String, input: String, expected: String) {
        #expect(HtmlSanitizer.removeStyleAttribute(html: input) == expected, Comment(rawValue: context))
    }

    @Test(
        "removes or escapes invalid characters correctly",
        arguments: [
            (
                "when empty html",
                "",
                ""
            ),
            (
                "when no special characters",
                "Hello",
                "Hello"
            ),
            (
                "when backslashes are present",
                #"C:\Temp\file"#,
                #"C:\\Temp\\file"#
            ),
            (
                "when single quote is present",
                #"Don't do it"#,
                #"Don\'t do it"#
            ),
            (
                "when double quotes are present",
                #"He said "hi""#,
                #"He said \"hi\""#
            ),
            (
                "when html attributes contain quotes and backslashes",
                #"<a href="C:\foo\bar" title='link'>"#,
                #"<a href=\"C:\\foo\\bar\" title=\'link\'>"#
            ),
        ])
    func removeInvalidCharacters(context: String, input: String, expected: String) {
        #expect(HtmlSanitizer.escapeQuotesAndBackslash(html: input) == expected, Comment(rawValue: context))
    }
}
