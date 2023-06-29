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
import ProtonCore_DataModel
import ProtonCore_Networking
@testable import ProtonMail
import ProtonCore_TestingToolkit
import XCTest

final class DeviceUnregistrationTests: XCTestCase {
    private var sut: DeviceUnregistration!
    private var dummySessionIDs: [String]!
    private var mockApiService: APIServiceMock!

    override func setUp() {
        super.setUp()
        mockApiService = APIServiceMock()
        dummySessionIDs = (1...4).map{ "dummyUser\($0)" }
        let dependencies = DeviceUnregistration.Dependencies(apiService: mockApiService)
        sut = DeviceUnregistration(dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        dummySessionIDs = nil
        mockApiService = nil
    }

    func testExecute_whenNoSessionsArePassed_itShouldReturnNoResults() async {
        mockApiService.setUpToRespondSuccessfully()

        let result = await sut.execute(sessionIDs: [], deviceToken: "token")

        XCTAssertEqual(result.count, 0)
    }

    func testExecute_whenAllRequestsSucceed_itShouldNotReturnErrors() async {
        mockApiService.setUpToRespondSuccessfully()

        let result = await sut.execute(sessionIDs: dummySessionIDs, deviceToken: "token")

        let errors = result.compactMap(\.error)
        XCTAssertEqual(result.count, dummySessionIDs.count)
        XCTAssertEqual(errors.count, 0)
    }

    func testExecute_whenOneRequestReturnsError_itShouldReturnErrorForThatSessionOnly() async {
        let failingSessionID = "failing session"
        let sessionIDsPlusOne = dummySessionIDs.appending(failingSessionID).shuffled()
        mockApiService.setUpToRespondWithError(forSession: failingSessionID)

        let result = await sut.execute(sessionIDs: sessionIDsPlusOne, deviceToken: "token")

        let failedResults = result.filter { $0.error != nil }
        XCTAssertEqual(result.count, sessionIDsPlusOne.count)
        XCTAssertEqual(failedResults.count, 1)
        XCTAssertEqual(failedResults.first?.sessionID, failingSessionID)
        switch failedResults.first?.error {
        case .responseError:
            XCTAssertTrue(true)
        default:
            XCTFail("wrong error")
        }
    }
}

private extension APIServiceMock {

    func setUpToRespondSuccessfully() {
        requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            guard path.contains("/devices") else {
                XCTFail("Wrong path")
                return
            }
            completion(nil, .success(JSONDictionary()))
        }
    }

    func setUpToRespondWithError(forSession session: String) {
        requestJSONStub.bodyIs { _, _, path, params, _, _, _, _, _, _, completion in
            guard path.contains("/devices") else {
                XCTFail("Wrong path")
                return
            }
            let reqParams = params as! [String: Any]
            if (reqParams["UID"] as? String) == session {
                completion(nil, .failure(NSError.badResponse()))
            } else {
                completion(nil, .success(JSONDictionary()))
            }
        }
    }
}
