// Copyright (c) 2022 Proton Technologies AG
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

import XCTest
@testable import ProtonMail

final class Array_ExtensionTests: XCTestCase {

    func testChunked() {
        let array = Array(0...20)
        let chunk1 = array.chunked(into: 3)
        XCTAssertEqual(chunk1.count, 7)
        for chunk in chunk1 {
            XCTAssertEqual(chunk.count, 3)
        }

        let chunk2 = array.chunked(into: 10)
        XCTAssertEqual(chunk2.count, 3)
        XCTAssertEqual(chunk2[safe: 0]?.count, 10)
        XCTAssertEqual(chunk2[safe: 1]?.count, 10)
        XCTAssertEqual(chunk2[safe: 2]?.count, 1)
    }

}
