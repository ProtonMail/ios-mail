// Copyright (c) 2021 Proton AG
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

class UndoTokenResponseProtocolTests: XCTestCase {

    var sut: ConversationLabelResponse!

    override func setUp() {
        super.setUp()
        sut = ConversationLabelResponse()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testParseUndoToken() {

        let undoResponse = [
            "Token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9",
            "ValidUntil": 1637823326
        ] as [String: Any]

        let response = [
            "UndoToken": undoResponse
        ] as [String: Any]

        sut.parseUndoToken(response: response)

        XCTAssertEqual(sut.undoTokenData?.token, undoResponse["Token"] as? String)
        XCTAssertEqual(sut.undoTokenData?.tokenValidTime, undoResponse["ValidUntil"] as? Int)
    }
}
