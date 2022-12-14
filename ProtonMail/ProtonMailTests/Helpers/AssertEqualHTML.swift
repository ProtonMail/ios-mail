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

import SwiftSoup
import XCTest

// This particular way of asserting is needed, because SwiftSoup does some minor stylistic changes, like adding
// missing <head> etc.
func assertHTMLsAreEqual(_ first: String, _ second: String, file: StaticString = #file, line: UInt = #line) {
    do {
        let firstDocument = try SwiftSoup.parse(first)
        let secondDocument = try SwiftSoup.parse(second)

        // pretty print needs to be disabled so that minor whitespace differences don't matter
        for document in [firstDocument, secondDocument] {
            document.outputSettings().prettyPrint(pretty: false)
        }

        // for some reason, a simple == check on two Nodes does not work - it's as if it was an identity check
        XCTAssertEqual("\(firstDocument)", "\(secondDocument)", file: file, line: line)
    } catch {
        XCTFail("\(error)", file: file, line: line)
    }
}
