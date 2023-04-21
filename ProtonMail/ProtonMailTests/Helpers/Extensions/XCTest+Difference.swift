// Copyright (c) 2023 Proton Technologies AG
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

import Difference
import XCTest

func XCTAssertEqual<T: Equatable>(
    _ received: @autoclosure () throws -> T,
    _ expected: @autoclosure () throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        let received = try received()
        let expected = try expected()
        XCTAssertTrue(
            received == expected, "Found difference for \n" + diff(expected, received).joined(separator: ", "),
            file: file,
            line: line
        )
    } catch {
        XCTFail("Caught error while testing: \(error)", file: file, line: line)
    }
}
