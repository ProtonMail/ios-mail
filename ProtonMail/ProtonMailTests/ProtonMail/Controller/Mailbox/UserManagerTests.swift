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

    override func setUp() {
        super.setUp()
        apiServiceMock = APIServiceMock()
    }

    override func tearDown() {
        super.tearDown()
        apiServiceMock = nil
    }

    func testGetUserID() {
        let userID = String.randomString(100)
        let fakeAuth = makeAuthCredential(userId: userID)
        let userInfo = makeUserInfo(userId: userID)
        let sut = UserManager(
            api: apiServiceMock,
            userInfo: userInfo,
            authCredential: fakeAuth,
            parent: nil
        )
        XCTAssertEqual(sut.userID.rawValue, userID)
    }

    func testBecomeActiveUser_whenTelemetryForUserIsDisabled_disablesTelemetry() {
        let userID = String.randomString(100)
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
        let userID = String.randomString(100)
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

}

private extension UserManagerTests {

    func makeAuthCredential(userId: String) -> AuthCredential {
        AuthCredential(
            sessionID: "",
            accessToken: "",
            refreshToken: "",
            expiration: Date(),
            userName: "",
            userID: userId,
            privateKey: nil,
            passwordKeySalt: nil
        )
    }

    func makeUserInfo(userId: String) -> UserInfo {
        UserInfo(
            maxSpace: nil,
            usedSpace: nil,
            language: nil,
            maxUpload: nil,
            role: nil,
            delinquent: nil,
            keys: nil,
            userId: userId,
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
