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
import ProtonCore_TestingToolkit

final class ExpandedHeaderViewModelTests: XCTestCase {

    var sut: ExpandedHeaderViewModel!
    var userMock: UserManager!
    var apiMock: APIServiceMock!
    var messageMock: Message!
    var contextProvider: MockCoreDataContextProvider!
    var dateFormatterMock: PMDateFormatter!

    override func setUpWithError() throws {
        apiMock = APIServiceMock()
        userMock = UserManager(api: apiMock, role: .none)
        contextProvider = MockCoreDataContextProvider()
        messageMock = Message(context: contextProvider.rootSavingContext)
        dateFormatterMock = PMDateFormatter()
        let label = Label(context: contextProvider.rootSavingContext)
        label.labelID = "12"
        _ = contextProvider.rootSavingContext.saveUpstreamIfNeeded()
    }

    override func tearDownWithError() throws {
        sut = nil
        userMock = nil
        apiMock = nil
        messageMock = nil
        contextProvider = nil
    }

    func testGetTime_fromScheduledMessage() {
        Environment.locale = { .enGB }
        Environment.currentDate = { Date.fixture("2022-04-22 01:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!
        dateFormatterMock.isDateInYesterday = { _ in false }
        dateFormatterMock.isDateInTomorrow = { _ in true }

        messageMock.add(labelID: "12")
        messageMock.time = Date.fixture("2022-04-23 18:00:00")
        sut = ExpandedHeaderViewModel(labelId: "12",
                                      message: MessageEntity(messageMock),
                                      user: userMock,
                                      dateFormatter: dateFormatterMock)

        XCTAssertEqual(sut.time.string, "Tomorrow, 18:00")
    }

    func testGetTime_fromNormalMessage() {
        Environment.locale = { .enGB }
        Environment.currentDate = { Date.fixture("2022-04-22 01:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!
        dateFormatterMock.isDateInTomorrow = { _ in true }
        dateFormatterMock.isDateInYesterday = { _ in false }

        messageMock.time = Date.fixture("2022-04-23 18:00:00")
        sut = ExpandedHeaderViewModel(labelId: "0",
                                      message: MessageEntity(messageMock),
                                      user: userMock,
                                      dateFormatter: dateFormatterMock)

        XCTAssertEqual(sut.time.string, "Saturday")
    }

    func testGetDate() {
        Environment.locale = { .enUS }
        Environment.currentDate = { Date.fixture("2022-04-22 00:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!

        let date = Date.fixture("2022-04-25 01:05:00")
        messageMock.time = date
        sut = ExpandedHeaderViewModel(labelId: "0",
                                      message: MessageEntity(messageMock),
                                      user: userMock,
                                      dateFormatter: dateFormatterMock)
        XCTAssertEqual(sut.date?.string, "April 25, 2022 at 1:05:00 AM")
    }
}
