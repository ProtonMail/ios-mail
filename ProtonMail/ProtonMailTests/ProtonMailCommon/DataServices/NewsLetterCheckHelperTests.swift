// Copyright (c) 2021 Proton Technologies AG
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

class NewsLetterCheckHelperTests: XCTestCase {

    var sut: NewsLetterCheckHelper!
    override func setUp() {
        super.setUp()
        sut = NewsLetterCheckHelper()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testCalculateIsNewsLetter() {
        let testHeader = "Return-Path: <reminders@test.com>\r\nX-Original-To: test@pm.me\r\nList-Unsubscribe:<https://test.test>\r\n"
        XCTAssertTrue(sut.calculateIsNewsLetter(messageHeaderString: testHeader))
    }

    func testCalculateIsNewsLetter_emptyString() {
        let testHeader = ""
        XCTAssertFalse(sut.calculateIsNewsLetter(messageHeaderString: testHeader))
    }
}
