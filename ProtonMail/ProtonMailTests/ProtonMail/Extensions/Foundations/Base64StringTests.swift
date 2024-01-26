// Copyright (c) 2024 Proton Technologies AG
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

final class Base64StringTests: XCTestCase {
    func testInsert() {
        let sut = Base64String(alreadyEncoded: "Zm9vCg==")
        let separator = "__"

        XCTAssertEqual(
            sut.insert(every: 2, with: separator),
            "Zm__9v__Cg__=="
        )

        XCTAssertEqual(
            sut.insert(every: 3, with: separator),
            "Zm9__vCg__=="
        )

        XCTAssertEqual(
            sut.insert(every: sut.encoded.count - 1, with: separator),
            "Zm9vCg=__="
        )

        // Watch out: the item is not appended at the end!
        XCTAssertEqual(
            sut.insert(every: sut.encoded.count, with: separator),
            "Zm9vCg=="
        )

        XCTAssertEqual(
            sut.insert(every: sut.encoded.count + 1, with: separator),
            "Zm9vCg=="
        )
    }
}
