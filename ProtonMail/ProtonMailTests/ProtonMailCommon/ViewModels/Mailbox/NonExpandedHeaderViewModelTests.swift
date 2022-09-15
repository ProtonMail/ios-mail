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

final class NonExpandedHeaderViewModelTests: XCTestCase {

    var sut: NonExpandedHeaderViewModel!
    var userMock: UserManager!
    var messageMock: Message!
    var apiMock: APIServiceMock!
    var dateFormatterMock: PMDateFormatter!
    var contextMock: MockCoreDataContextProvider!

    override func setUp() {
        super.setUp()

        apiMock = APIServiceMock()
        userMock = UserManager(api: apiMock, role: .none)
        contextMock = MockCoreDataContextProvider()
        messageMock = Message(context: contextMock.rootSavingContext)
        dateFormatterMock = PMDateFormatter()

        let label = Label(context: contextMock.rootSavingContext)
        label.labelID = "12"
        _ = contextMock.rootSavingContext.saveUpstreamIfNeeded()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        userMock = nil
        apiMock = nil
        messageMock = nil
        dateFormatterMock = nil
        contextMock = nil
    }

    func testGetTime_fromScheduledMessage() {
        Environment.locale = { .enGB }
        Environment.currentDate = { Date.fixture("2022-04-22 01:00:00") }
        Environment.timeZone = TimeZone(secondsFromGMT: 0)!
        dateFormatterMock.isDateInYesterday = { _ in false }
        dateFormatterMock.isDateInTomorrow = { _ in true }

        messageMock.add(labelID: "12")
        messageMock.time = Date.fixture("2022-04-23 18:00:00")
        sut = NonExpandedHeaderViewModel(labelId: "12",
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
        sut = NonExpandedHeaderViewModel(labelId: "0",
                                         message: MessageEntity(messageMock),
                                         user: userMock,
                                         dateFormatter: dateFormatterMock)

        XCTAssertEqual(sut.time.string, "Saturday")
    }

    func testSetupTimer_messageIsScheduleSend_closureIsCalled() {
        messageMock.flags = NSNumber(value: MessageFlag.scheduledSend.rawValue)
        let expectation1 = expectation(description: "Closure is called")
        sut = NonExpandedHeaderViewModel(labelId: "0",
                                         message: MessageEntity(messageMock),
                                         user: userMock)
        sut.updateTimeLabel = {
            expectation1.fulfill()
        }

        sut.setupTimerIfNeeded()

        waitForExpectations(timeout: 3)
    }

    func testSetupTimer_messageIsNotScheduleSend_closureIsNotCalled() {
        let expectation1 = expectation(description: "Closure is not called")
        expectation1.isInverted = true
        sut = NonExpandedHeaderViewModel(labelId: "0",
                                         message: MessageEntity(messageMock),
                                         user: userMock)
        sut.updateTimeLabel = {
            XCTFail("This closure should not be called since it is not a scheduled-send message.")
        }

        sut.setupTimerIfNeeded()

        waitForExpectations(timeout: 3)
    }
}
