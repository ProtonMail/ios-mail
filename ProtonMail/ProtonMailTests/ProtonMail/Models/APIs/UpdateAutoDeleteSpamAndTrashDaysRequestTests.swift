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

@testable import ProtonMail
import XCTest

final class UpdateAutoDeleteSpamAndTrashDaysRequestTests: XCTestCase {
    func testInit() throws {
        let value = Bool.random()
        let sut = UpdateAutoDeleteSpamAndTrashDaysRequest(shouldEnable: value)

        let parameter = try XCTUnwrap(sut.parameters?["Days"] as? Int)
        XCTAssertEqual(parameter, value == true ? 30 : 0)
    }
}
