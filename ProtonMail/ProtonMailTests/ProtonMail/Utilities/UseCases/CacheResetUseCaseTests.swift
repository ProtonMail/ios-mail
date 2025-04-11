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

import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

final class CacheResetUseCaseTests: XCTestCase {
    var container: TestContainer!
    var sut: CacheResetUseCase!
    var user: UserManager!
    var apiMock: APIServiceMock!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = .init()
        apiMock = .init()
        user = try UserManager.prepareUser(apiMock: apiMock, globalContainer: container)
        sut = .init(dependencies: user.container)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        user = nil
        apiMock = nil
    }

    func testExecute_conversationMode_eventIDWillBeUpdated() async throws {
        let newEventID = String.randomString(20)
        apiMock.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            if path == "/core/v4/events/latest" {
                completion(nil, .success(["EventID": newEventID]))
            } else if path == "/mail/v4/conversations?Limit=50&LabelID=5&Desc=1&Sort=Time" {
                completion(nil, .success(["Conversations": []]))
            } else {
                completion(nil, .success([:]))
            }
        }

        try await sut.execute(type: .all)

        let eventID = container.lastUpdatedStore.lastEventID(userID: user.userID)
        XCTAssertEqual(eventID, newEventID)
    }

    func testExecute_singleMessage_eventIDWillBeUpdated() async throws {
        user.conversationStateService.viewMode = .singleMessage
        let newEventID = String.randomString(20)
        apiMock.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            if path == "/core/v4/events/latest" {
                completion(nil, .success(["EventID": newEventID]))
            } else if path == "/mail/v4/messages" {
                completion(nil, .success(["Messages": []]))
            } else {
                completion(nil, .success([:]))
            }
        }

        try await sut.execute(type: .all)

        let eventID = container.lastUpdatedStore.lastEventID(userID: user.userID)
        XCTAssertEqual(eventID, newEventID)
    }
}
