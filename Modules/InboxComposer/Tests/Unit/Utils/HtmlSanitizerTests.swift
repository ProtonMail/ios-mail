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
import Testing
import proton_app_uniffi

@testable import InboxComposer

final class HtmlSanitizerTests {
    @Test(
        "applies JS string literal escaping rules",
        arguments: [
            (
                "when empty string",
                "",
                "\"\""
            ),
            (
                "when normal ascii",
                "Hello",
                "\"Hello\""
            ),
            (
                "when contains quotes",
                #"He said: "hi""#,
                "\"He said: \\\"hi\\\"\""
            ),
            (
                "when contains backslashes",
                #"C:\test\file"#,
                "\"C:\\\\test\\\\file\""
            ),
            (
                "when contains newline",
                "line1\nline2",
                "\"line1\\nline2\""
            ),
            (
                "when contains tab",
                "col1\tcol2",
                "\"col1\\tcol2\""
            ),
            (
                "when contains emoji",
                "Hello 🙂",
                "\"Hello 🙂\""
            ),
        ])
    func applyStringLiteralEscapingRules(context: String, input: String, expected: String) {
        #expect(HtmlSanitizer.applyStringLiteralEscapingRules(html: input) == expected, Comment(rawValue: context))
    }
}
