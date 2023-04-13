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

import CoreData
import Foundation
@testable import ProtonMail
import ProtonCore_TestingToolkit
import XCTest

final class EventsServiceTests: XCTestCase {
    private var sut: EventsService!
    private var mockApiService: APIServiceMock!
    private var mockUserManager: UserManager!
    private var mockContactCache: MockContactCacheStatusProtocol!
    private var mockFetchMessageMetaData: FetchMessageMetaDataUseCase!
    private var mockContactCacheStatus: ContactCacheStatusProtocol!
    private var mockContextProvider: CoreDataContextProviderProtocol!
    private let dummyUserID = "dummyUserID"
    private let timeout = 2.0

    override func setUp() {
        mockApiService = APIServiceMock()
        mockUserManager = makeUserManager(apiMock: mockApiService)
        mockContactCache = MockContactCacheStatusProtocol()
        mockFetchMessageMetaData = MockFetchMessageMetaData()
        mockContactCacheStatus = MockContactCacheStatusProtocol()
        mockContextProvider = MockCoreDataContextProvider()
        let incomingDefaultService = IncomingDefaultService(
            dependencies: .init(
                apiService: mockApiService,
                contextProvider: mockContextProvider,
                userInfo: mockUserManager.userInfo
            )
        )
        let dependencies = EventsService.Dependencies(
            fetchMessageMetaData: mockFetchMessageMetaData,
            contactCacheStatus: mockContactCacheStatus,
            incomingDefaultService: incomingDefaultService,
            coreDataProvider: mockContextProvider
        )
        sut = EventsService(userManager: mockUserManager, dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        mockApiService = nil
        mockUserManager = nil
        mockContactCache = nil
        mockFetchMessageMetaData = nil
        mockContactCacheStatus = nil
        mockContextProvider = nil
        sut = nil
    }

    func testFetchEvents_whenNewIncomingDefault_itSucceedsSavingIt() {
        let objectId = String.randomString(32)
        let objectEmail = "dummy@example.com"
        let objectTime: TimeInterval = 1678721296
        let objectLocation = "14"
        mockApiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            if path.contains("/events") {
                let result = self.newBlockedSenderEventJson(
                    id: objectId,
                    email: objectEmail,
                    time: objectTime,
                    location: objectLocation
                ).toDictionary()!
                completion(nil, .success(result))
            }
        }

       let expectation = expectation(description: "")
        sut.start() // needed to set the correct sut status
        sut.fetchEvents(byLabel: LabelID(rawValue: "anylabel"), notificationMessageID: nil) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout)

        try! mockContextProvider.read { context in
            let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.entity().name!)
            let incomingDefaults = try context.fetch(fetchRequest)
            XCTAssertEqual(incomingDefaults.count, 1)
            let matchingStoredObject: IncomingDefault = try XCTUnwrap(incomingDefaults.first { $0.id == objectId })
            XCTAssertEqual(matchingStoredObject.email, objectEmail)
            XCTAssertEqual(matchingStoredObject.location, objectLocation)
            XCTAssertEqual(matchingStoredObject.time.timeIntervalSince1970, objectTime)
            XCTAssertEqual(matchingStoredObject.userID, dummyUserID)
        }
    }

    func testFetchEvents_whenNewIncomingDefaultForRemovedBlockedSender_itSucceedsRemovingIt() {
        let incomingDefaultId = String.randomString(32)
        mockContextProvider.enqueueOnRootSavingContext { context in
            let incomingDefault = IncomingDefault(context: context)
            incomingDefault.userID = self.dummyUserID
            incomingDefault.id = incomingDefaultId
            incomingDefault.email = String.randomString(15)
            incomingDefault.location = "14"
            incomingDefault.time = Date()
            _ = context.saveUpstreamIfNeeded()
        }
        mockApiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            if path.contains("/events") {
                let result = self.removedBlockedSenderEventJson(id: incomingDefaultId).toDictionary()!
                completion(nil, .success(result))
            }
        }

        let expectation = expectation(description: "")
        sut.start() // needed to set the correct sut status
        sut.fetchEvents(byLabel: LabelID(rawValue: "anylabel"), notificationMessageID: nil) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout)

        try! mockContextProvider.read { context in
            let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.entity().name!)
            let incomingDefaults = try context.fetch(fetchRequest)
            XCTAssertEqual(incomingDefaults.count, 0)
        }
    }

    func testFetchEvents_whenNewIncomingDefaultForBlockedSenderMovedToSpam_itSucceedsUpdatingIt() {
        let incomingDefaultId = String.randomString(32)
        let imcomingDefaultEmail = "random@example.com"
        mockContextProvider.enqueueOnRootSavingContext { context in
            let incomingDefault = IncomingDefault(context: context)
            incomingDefault.userID = self.dummyUserID
            incomingDefault.id = incomingDefaultId
            incomingDefault.email = imcomingDefaultEmail
            incomingDefault.location = "\(IncomingDefaultsAPI.Location.blocked.rawValue)"
            incomingDefault.time = Date.distantPast
            _ = context.saveUpstreamIfNeeded()
        }
        mockApiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            if path.contains("/events") {
                let result = self.movedBlockedSenderToSpamEventJson(
                    id: incomingDefaultId,
                    email: imcomingDefaultEmail
                ).toDictionary()!
                completion(nil, .success(result))
            }
        }

        let expectation = expectation(description: "")
        sut.start() // needed to set the correct sut status
        sut.fetchEvents(byLabel: LabelID(rawValue: "anylabel"), notificationMessageID: nil) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout)

        try! mockContextProvider.read { context in
            let fetchRequest = NSFetchRequest<IncomingDefault>(entityName: IncomingDefault.entity().name!)
            let incomingDefaults = try context.fetch(fetchRequest)
            XCTAssertEqual(incomingDefaults.count, 1)
            let matchingStoredObject: IncomingDefault = try XCTUnwrap(incomingDefaults.first {
                $0.id == incomingDefaultId
            })
            XCTAssertEqual(matchingStoredObject.location, "\(IncomingDefaultsAPI.Location.spam.rawValue)")
        }
    }
}

extension EventsServiceTests {

    private func makeUserManager(apiMock: APIServiceMock) -> UserManager {
        let user = UserManager(api: apiMock, role: .member)
        user.userInfo.userId = dummyUserID
        return user
    }
}

extension EventsServiceTests {

    private func newBlockedSenderEventJson(id: String, email: String, time: TimeInterval, location: String) -> String {
        return """
        {
          "Code": 1000,
          "EventID": "1XyDltMaDjGe0ss_Ww5XwyuC9GEzMtMXOVkHFsapuODZLJ_tlm8NxPp2mtNN5Wli6bQCt84UylUHHpZQDROrvg==",
          "Refresh": 0,
          "More": 0,
          "IncomingDefaults": [
            {
              "ID": "\(id)",
              "Action": 1,
              "IncomingDefault": {
                "ID": "\(id)",
                "Location": \(location),
                "Type": 1,
                "Time": \(time),
                "Email": "\(email)"
              }
            }
          ],
          "Pushes": [],
          "Notices": []
        }
        """
    }

    private func removedBlockedSenderEventJson(id: String) -> String {
        return """
        {
          "Code": 1000,
          "EventID": "fVWF9HoEza6cSK75iJRrXH6bYhTgPEvijpkJS7qnAKi8_dMNVLvNmxc0_AsXwYiwrr7bKqCWGh2TgG51OpDVFQ==",
          "Refresh": 0,
          "More": 0,
          "IncomingDefaults": [
            {
              "ID": "\(id)",
              "Action": 0
            }
          ],
          "Pushes": [],
          "Notices": []
        }
        """
    }

    private func movedBlockedSenderToSpamEventJson(id: String, email: String) -> String {
        return """
        {
          "Code": 1000,
          "EventID": "va8rKRAyI54YHXAWU_VoW4VhBnJEoQ-NLavt4osGrvH4Exrl8KAK4swHkhN6o-uWbxlZh-fZWFBZBhPbTLjTpA==",
          "Refresh": 0,
          "More": 0,
          "IncomingDefaults": [
            {
              "ID": "\(id)",
              "Action": 2,
              "IncomingDefault": {
                "ID": "\(id)",
                "Location": 4,
                "Type": 1,
                "Time": 1678723854,
                "Email": "\(email)"
              }
            }
          ],
          "Pushes": [],
          "Notices": []
        }
        """
    }
}
