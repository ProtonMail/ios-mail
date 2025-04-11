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

import Foundation
import ProtonCoreDataModel
import ProtonCoreNetworking
@testable import ProtonMail
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

final class DeviceRegistrationTests: XCTestCase {
    private var sut: DeviceRegistration!
    private var sessionIds: [String]!
    private var mockUsers: UsersManager!
    private var mockApiService: APIServiceMock!
    private var mockFailingApiService: APIServiceMock!
    private var dependencies: DeviceRegistration.Dependencies!
    private var globalContainer: TestContainer!

    override func setUp() {
        super.setUp()
        globalContainer = .init()
        mockApiService = APIServiceMock()
        mockFailingApiService = APIServiceMock()
        globalContainer = .init()
        mockUsers = globalContainer.usersManager
        sessionIds = (1...4).map{ "dummyUser\($0)" }
        sessionIds.map { createUserManager(userID: $0, apiService: mockApiService) }.forEach { mockUser in
            mockUsers.add(newUser: mockUser)
        }
        dependencies = DeviceRegistration.Dependencies(usersManager: mockUsers)
        sut = DeviceRegistration(dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        dependencies = nil
        globalContainer = nil
        sessionIds = nil
        mockUsers = nil
        mockApiService = nil
        globalContainer = nil
    }

    func testExecute_whenNoSessionsArePassed_itShouldReturnNoResults() async {
        mockApiService.setUpToRespondSuccessfully()

        let result = await sut.execute(sessionIDs: [], deviceToken: "token", publicKey: "public key")

        XCTAssertEqual(result.count, 0)
    }

    func testExecute_whenAllRequestsSucceed_itShouldNotReturnErrors() async {
        mockApiService.setUpToRespondSuccessfully()

        let result = await sut.execute(sessionIDs: sessionIds, deviceToken: "token", publicKey: "public key")

        let errors = result.compactMap(\.error)
        XCTAssertEqual(result.count, sessionIds.count)
        XCTAssertEqual(errors.count, 0)
    }

    func testExecute_whenSessionDoesNotExist_itShouldReturnErrorForThatSessionOnly() async {
        let sessionIdsPlusOne = sessionIds.appending("made up session").shuffled()
        mockApiService.setUpToRespondSuccessfully()

        let result = await sut.execute(sessionIDs: sessionIdsPlusOne, deviceToken: "token", publicKey: "public key")

        let errors = result.compactMap(\.error)
        XCTAssertEqual(result.count, sessionIdsPlusOne.count)
        XCTAssertEqual(errors.count, 1)
        switch errors.first! {
        case .noSessionIdFound(let sessionId):
            XCTAssertEqual(sessionId, "made up session")
        default:
            XCTFail("wrong error")
        }
    }

    func testExecute_whenOneRequestReturnsError_itShouldReturnErrorForThatSessionOnly() async {
        let failingSessionId = "failing session"
        let sessionIdsPlusOne = sessionIds.appending(failingSessionId).shuffled()
        mockUsers.add(newUser: createUserManager(userID: failingSessionId, apiService: mockFailingApiService))
        mockApiService.setUpToRespondSuccessfully()
        mockFailingApiService.setUpToRespondWithError()

        let result = await sut.execute(sessionIDs: sessionIdsPlusOne, deviceToken: "token", publicKey: "public key")

        let failedResults = result.filter { $0.error != nil }
        XCTAssertEqual(result.count, sessionIdsPlusOne.count)
        XCTAssertEqual(failedResults.count, 1)
        XCTAssertEqual(failedResults.first?.sessionID, failingSessionId)
        switch failedResults.first?.error {
        case .responseError:
            XCTAssertTrue(true)
        default:
            XCTFail("wrong error")
        }
    }
}

private extension DeviceRegistrationTests {

    func createUserManager(userID: String, apiService: APIServiceMock) -> UserManager {
        let userInfo = UserInfo(
            maxSpace: nil,
            maxBaseSpace: nil,
            maxDriveSpace: nil,
            usedSpace: nil,
            usedBaseSpace: nil,
            usedDriveSpace: nil,
            language: nil,
            maxUpload: nil,
            role: 0,
            delinquent: nil,
            keys: [],
            userId: userID,
            linkConfirmation: nil,
            credit: nil,
            currency: nil,
            createTime: nil,
            subscribed: nil,
            edmOptOut: nil
        )
        let auth = AuthCredential(
            Credential(
                UID: "\(userID)",
                accessToken: "",
                refreshToken: "",
                userName: userID,
                userID: userID,
                scopes: []
            )
        )
        return UserManager(
            api: apiService,
            userInfo: userInfo,
            authCredential: auth,
            mailSettings: nil,
            parent: nil,
            globalContainer: globalContainer
        )
    }
}

private extension APIServiceMock {

    func setUpToRespondSuccessfully() {
        requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success(JSONDictionary()))
        }
    }

    func setUpToRespondWithError() {
        requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .failure(NSError.badResponse()))
        }
    }
}
