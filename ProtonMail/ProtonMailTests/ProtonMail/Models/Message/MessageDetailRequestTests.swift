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

import XCTest
@testable import ProtonMail

final class MessageDetailRequestTests: XCTestCase {
    var sut: MessageDetailRequest!
    var messageID: MessageID = .init(String.randomString(20))
    var priority: APIPriority!

    override func setUp() {
        priority = APIPriority.allCases[Int.random(in: 0...7)]
    }

    override func tearDown() {
        priority = nil
    }

    func testInit() throws {
        sut = .init(messageID: messageID, priority: priority)

        XCTAssertEqual(sut.path, "/\(Constants.App.API_PREFIXED)/messages/\(messageID.rawValue)")
        let value = try XCTUnwrap(sut.header["priority"] as? String)
        XCTAssertEqual(value, priority.rawValue)
    }

    func testInitWithoutPriority() {
        sut = .init(messageID: messageID)

        XCTAssertEqual(sut.path, "/\(Constants.App.API_PREFIXED)/messages/\(messageID.rawValue)")
        XCTAssertNil(sut.header["priority"])
    }
}
