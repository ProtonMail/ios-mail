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

class ScheduleSendLocationStatusObserverTests: XCTestCase {

    var sut: ScheduleSendLocationStatusObserver!
    var contextProviderMock: MockCoreDataContextProvider!
    var userID: UserID = UserID(rawValue: "UserID")

    override func setUp() {
        super.setUp()
        contextProviderMock = MockCoreDataContextProvider()
        sut = ScheduleSendLocationStatusObserver(
            contextProvider: contextProviderMock,
            userID: userID
        )
        generateLabelData()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        contextProviderMock = nil
    }

    func testObserve_getCountValueFromCoreData() throws {
        generateTestDataInCoreData(count: 1)
        let expectation1 = expectation(description: "Closure should not be called")
        expectation1.isInverted = true

        let result = sut.observe { _ in
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertTrue(result)
    }

    func testObserve_closureBeingCalled_whenMessageCountChanged() throws {
        let expectation1 = expectation(description: "Closure is called")

        let result = sut.observe { newValue in
            XCTAssertTrue(newValue)
            expectation1.fulfill()
        }
        XCTAssertFalse(result)
        generateTestDataInCoreData(count: 1)
        waitForExpectations(timeout: 5, handler: nil)
    }

    private func generateLabelData() {
        let testContext = contextProviderMock.mainContext
        let label = Label(context: testContext)
        label.labelID = "12"
        _ = testContext.saveUpstreamIfNeeded()
    }

    private func generateTestDataInCoreData(count: Int) {
        let testContext = contextProviderMock.mainContext
        for _ in 0..<count {
            let msg = Message(context: testContext)
            msg.add(labelID: "12")
            msg.messageID = String.randomString(20)
            msg.userID = userID.rawValue
            msg.messageStatus = NSNumber(value: 1)
            msg.isSoftDeleted = false
        }
        _ = testContext.saveUpstreamIfNeeded()
    }
}
