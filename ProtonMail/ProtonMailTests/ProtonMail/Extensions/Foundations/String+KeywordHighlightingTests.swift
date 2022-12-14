// Copyright (c) 2022 Proton Technologies AG
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

import XCTest

@testable import ProtonMail

class String_KeywordHighlightingTests: XCTestCase {
    private var html: String {
"""
<html>
<head></head>
<body>
<p>Hello 😀,</p>
<p>You have 1 new message(s) in your inbox and custom folders.</p>
<p>Please log in at <a href="https://mail.proton.me">https://mail.proton.me</a> to check them. These notifications can be turned off by logging into your account and disabling the daily notification setting.</p>
<p>Best regards 😀,</p>
<p>The ProtonMail Team</p>
</body>
</html>
"""
    }

    private var keywords: [String] {
        ["custóm", "FOLDER", "😀", "old"]
    }

    func testHighlightingWithCSS() {
        let result = html.keywordHighlighting.usingCSS(keywords: keywords)

        let expectedResult: String = """
<html>
<head></head>
<body>
<p><span>Hello <mark style="background-color: #8A6EFF4D" id="es-autoscroll">😀</mark>,</span></p>
<p><span>You have 1 new message(s) in your inbox and <mark style="background-color: #8A6EFF4D" id="es-autoscroll">custom</mark> <mark style="background-color: #8A6EFF4D" id="es-autoscroll">folder</mark>s.</span></p>
<p>Please log in at <a href="https://mail.proton.me">https://mail.proton.me</a> to check them. These notifications can be turned off by logging into your account and disabling the daily notification setting.</p>
<p><span>Best regards <mark style="background-color: #8A6EFF4D" id="es-autoscroll">😀</mark>,</span></p>
<p>The ProtonMail Team</p>
</body>
</html>
"""

        assertHTMLsAreEqual(result, expectedResult)
    }

    func testHighlightingAsAttributedString() throws {
        let result = html.keywordHighlighting.asAttributedString(keywords: keywords)

        XCTAssertEqual(result.string, html)

        let range = NSRange(location: 0, length: result.length)

        let expectations: [NSRange: XCTestExpectation] = [
            NSRange(location:37, length: 2): expectation(description: "1st 😀 is highlighted"),
            NSRange(location:92, length: 6): expectation(description: "custom is highlighted"),
            NSRange(location:99, length: 6): expectation(description: "folder is highlighted"),
            NSRange(location:340, length: 2): expectation(description: "2nd 😀 is highlighted")
        ]

        result.enumerateAttribute(.backgroundColor, in: range) { value, highlightedRange, _ in
            guard let color = value as? UIColor, color.rrggbbaa == "8A6EFF4D" else {
                return
            }

            guard let expectation = expectations[highlightedRange] else {
                let highlightedText = result.attributedSubstring(from: highlightedRange).string
                XCTFail("Unexpected range highlighted: \(highlightedRange) (\"\(highlightedText)\").")
                return
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
