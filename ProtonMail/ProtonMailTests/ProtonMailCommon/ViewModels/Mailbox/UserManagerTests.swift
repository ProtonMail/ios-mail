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
        let fakeAuth = AuthCredential(sessionID: "",
                                      accessToken: "",
                                      refreshToken: "",
                                      expiration: Date(),
                                      userName: "",
                                      userID: userID,
                                      privateKey: nil,
                                      passwordKeySalt: nil)
        let userInfo = UserInfo(maxSpace: nil,
                                usedSpace: nil,
                                language: nil,
                                maxUpload: nil,
                                role: nil,
                                delinquent: nil,
                                keys: nil,
                                userId: userID,
                                linkConfirmation: nil,
                                credit: nil,
                                currency: nil,
                                subscribed: nil)
        let sut = UserManager(api: apiServiceMock,
                              userInfo: userInfo,
                              authCredential: fakeAuth,
                              parent: nil)
        XCTAssertEqual(sut.userID.rawValue, userID)
    }
}
