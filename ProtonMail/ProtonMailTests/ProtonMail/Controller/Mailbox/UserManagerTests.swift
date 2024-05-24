// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreTestingToolkitUnitTestsServices

class UserManagerTests: XCTestCase {
    private var mockAppTelemetry: MockAppTelemetry!
    private var userID: UserID!
    private var sut: UserManager!
    private var testContainer: TestContainer!

    override func setUp() {
        super.setUp()
        
        testContainer = .init()
        mockAppTelemetry = .init()
        userID = UserID(String.randomString(100))
        sut = UserManager(api: APIServiceMock(), userID: userID.rawValue, appTelemetry: mockAppTelemetry)
        sut.parentManager = testContainer.usersManager
        testContainer.usersManager.add(newUser: sut)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockAppTelemetry = nil
        userID = nil
        testContainer = nil
    }

    func testGetUserID() {
        XCTAssertEqual(sut.userID, userID)
    }

    func testToolbarActionsIsStandard() {
        sut.userInfo.messageToolbarActions.isCustom = false
        sut.userInfo.listToolbarActions.isCustom = false
        sut.userInfo.conversationToolbarActions.isCustom = false

        XCTAssertTrue(sut.toolbarActionsIsStandard)
    }

    func testBecomeActiveUser_whenTelemetryForUserIsDisabled_disablesTelemetry() {
        sut.userInfo.telemetry = 0

        sut.becomeActiveUser()
        XCTAssertTrue(mockAppTelemetry.configureStub.wasCalled)
        XCTAssertEqual(mockAppTelemetry.configureStub.lastArguments?.a1, false)
    }

    func testBecomeActiveUser_whenTelemetryForUserIsEnabled_enablesTelemetry() {
        sut.userInfo.telemetry = 1

        sut.becomeActiveUser()
        XCTAssertTrue(mockAppTelemetry.configureStub.wasCalled)
        XCTAssertEqual(mockAppTelemetry.configureStub.lastArguments?.a1, true)
    }

    func testBecomeActiveUser_regardlessOfTelemerySetting_assignsTheUserToAnalytics() {
        sut.userInfo.telemetry = Int.random(in: 0...1)

        sut.becomeActiveUser()

        XCTAssertEqual(mockAppTelemetry.assignUserStub.callCounter, 1)
        XCTAssertEqual(mockAppTelemetry.assignUserStub.lastArguments?.a1, sut.userID)
    }

    func testResignAsActiveUser_regardlessOfTelemerySetting_clearsTheUserIDAssignedToAnalytics() {
        sut.userInfo.telemetry = Int.random(in: 0...1)

        sut.resignAsActiveUser()

        XCTAssertEqual(mockAppTelemetry.assignUserStub.callCounter, 1)
        XCTAssertNil(mockAppTelemetry.assignUserStub.lastArguments?.a1)
    }

    func testGetMessageToolbarActions() {
        sut.userInfo.messageToolbarActions.actions = ["label", "print"]

        XCTAssertEqual(sut.messageToolbarActions, [.labelAs, .print])
    }

    func testSetMessageToolbarActions() {
        sut.messageToolbarActions = [.labelAs, .print]

        XCTAssertEqual(sut.userInfo.messageToolbarActions.actions, ["label", "print"])
    }

    func testGetListViewToolbarActions() {
        sut.userInfo.listToolbarActions.actions = ["label", "print"]

        XCTAssertEqual(sut.listViewToolbarActions, [.labelAs, .print])
    }

    func testSetListViewToolbarActions() {
        sut.listViewToolbarActions = [.labelAs, .print]

        XCTAssertEqual(sut.userInfo.listToolbarActions.actions, ["label", "print"])
    }
}
