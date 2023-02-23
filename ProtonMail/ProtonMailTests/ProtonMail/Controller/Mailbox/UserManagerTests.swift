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
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_TestingToolkit

class UserManagerTests: XCTestCase {
    var apiServiceMock: APIServiceMock!
    var sut: UserManager!
    var defaultUserID: UserID = "1"

    override func setUp() {
        super.setUp()
        apiServiceMock = APIServiceMock()
        makeSUT(userID: defaultUserID)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        apiServiceMock = nil
    }

    func testGetUserID() {
        let userID = UserID(String.randomString(100))
        let fakeAuth = makeAuthCredential(userId: userID)
        let userInfo = makeUserInfo(userId: userID)
        let sut = UserManager(
            api: apiServiceMock,
            userInfo: userInfo,
            authCredential: fakeAuth,
            parent: nil
        )
        XCTAssertEqual(sut.userID, userID)
    }

    func testToolbarActionsIsStandard() {
        sut.userInfo.messageToolbarActions.isCustom = false
        sut.userInfo.listToolbarActions.isCustom = false
        sut.userInfo.conversationToolbarActions.isCustom = false

        XCTAssertTrue(sut.toolbarActionsIsStandard)
    }

    func testBecomeActiveUser_whenTelemetryForUserIsDisabled_disablesTelemetry() {
        let userID = UserID(String.randomString(100))
        let fakeAuth = makeAuthCredential(userId: userID)
        let userInfo = makeUserInfo(userId: userID)
        let mockAppTelemetry = MockAppTelemetry()

        userInfo.telemetry = 0

        let sut = UserManager(
            api: apiServiceMock,
            userInfo: userInfo,
            authCredential: fakeAuth,
            parent: nil,
            appTelemetry: mockAppTelemetry
        )

        sut.becomeActiveUser()
        XCTAssertFalse(mockAppTelemetry.enableWasCalled)
        XCTAssertTrue(mockAppTelemetry.disableWasCalled)
    }

    func testBecomeActiveUser_whenTelemetryForUserIsEnabled_enablesTelemetry() {
        let userID = UserID(String.randomString(100))
        let fakeAuth = makeAuthCredential(userId: userID)
        let userInfo = makeUserInfo(userId: userID)
        let mockAppTelemetry = MockAppTelemetry()

        userInfo.telemetry = 1

        let sut = UserManager(
            api: apiServiceMock,
            userInfo: userInfo,
            authCredential: fakeAuth,
            parent: nil,
            appTelemetry: mockAppTelemetry
        )

        sut.becomeActiveUser()
        XCTAssertTrue(mockAppTelemetry.enableWasCalled)
        XCTAssertFalse(mockAppTelemetry.disableWasCalled)
    }

    func testGetMessageToolbarActions() {
        sut.userInfo.messageToolbarActions.actions = ["label", "print"]

        XCTAssertEqual(sut.messageToolbarActions, [.labelAs, .print])
    }

    func testSetMessageToolbarActions() {
        sut.messageToolbarActions = [.labelAs, .print]

        XCTAssertEqual(sut.userInfo.messageToolbarActions.actions, ["label", "print"])
    }

    func testGetConversationToolbarActions() {
        sut.userInfo.conversationToolbarActions.actions = ["label", "print"]

        XCTAssertEqual(sut.conversationToolbarActions, [.labelAs, .print])
    }

    func testSetConversationToolbarActions() {
        sut.conversationToolbarActions = [.labelAs, .print]

        XCTAssertEqual(sut.userInfo.conversationToolbarActions.actions, ["label", "print"])
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

private extension UserManagerTests {
    func makeSUT(userID: UserID) {
        let fakeAuth = makeAuthCredential(userId: userID)
        let userInfo = makeUserInfo(userId: userID)
        sut = UserManager(
            api: apiServiceMock,
            userInfo: userInfo,
            authCredential: fakeAuth,
            parent: nil
        )
    }

    func makeAuthCredential(userId: UserID) -> AuthCredential {
        AuthCredential(
            sessionID: "",
            accessToken: "",
            refreshToken: "",
            expiration: Date(),
            userName: "",
            userID: userId.rawValue,
            privateKey: nil,
            passwordKeySalt: nil
        )
    }

    func makeUserInfo(userId: UserID) -> UserInfo {
        UserInfo(
            maxSpace: nil,
            usedSpace: nil,
            language: nil,
            maxUpload: nil,
            role: nil,
            delinquent: nil,
            keys: nil,
            userId: userId.rawValue,
            linkConfirmation: nil,
            credit: nil,
            currency: nil,
            subscribed: nil
        )
    }
}

class MockAppTelemetry: AppTelemetry {
    private(set) var enableWasCalled: Bool = false
    private(set) var disableWasCalled: Bool = false

    func enable() {
        enableWasCalled = true
    }

    func disable() {
        disableWasCalled = true
    }
}
