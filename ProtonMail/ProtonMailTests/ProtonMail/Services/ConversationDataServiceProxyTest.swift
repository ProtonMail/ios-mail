// Copyright (c) 2024 Proton Technologies AG
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
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest
@testable import ProtonMail

final class ConversationDataServiceProxyTest: XCTestCase {
    private var sut: ConversationDataServiceProxy!
    private var globalContainer: TestContainer!
    private var userContainer: UserContainer!
    private var mockApiService: APIServiceMock!
    private var userManager: UserManager!
    private let userID: String = "abc"

    override func setUpWithError() throws {
        mockApiService = APIServiceMock()
        userManager = UserManager(api: mockApiService, userID: userID)
        globalContainer = TestContainer()
        userContainer = UserContainer(userManager: userManager, globalContainer: globalContainer)
        sut = userContainer.conversationService
        userContainer.queueManager.registerHandler(userContainer.queueHandler)
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        userManager = nil
        mockApiService = nil
        userContainer = nil
        globalContainer = nil
        sut = nil
        try super.tearDownWithError()
    }

    func testLabelConversation_addANewCustomLabel_itShouldHaveNewLabel() async throws {
        let conversationID = try await mockConversation()
        let ex = expectation(description: "Label finish")
        let apiIsCalled = expectation(description: "Api is called")
        let customLabel = LabelID(String.randomString(6))

        mockApiService.requestJSONStub.bodyIs { _, method, path, body, _, _, _, _, _, _, _, _, completion in
            defer { apiIsCalled.fulfill() }
            XCTAssertEqual(method, .put)
            XCTAssertEqual(path, "/mail/v4/conversations/label")
            guard
                let bodyDict = body as? [String: Any],
                let ids = bodyDict["IDs"] as? [String],
                let labelID = bodyDict["LabelID"] as? String
            else {
                XCTFail("Can't get expected data")
                return
            }
            XCTAssertEqual(ids, [conversationID.rawValue])
            XCTAssertEqual(labelID, customLabel.rawValue)
            completion(nil, .success([:]))
        }

        sut.label(
            conversationIDs: [conversationID],
            as: customLabel
        ) { result in
            switch result {
            case .success:
                let labelIDs = self.sortedLabelIDs(from: conversationID)
                let expectationLabelIDs = [
                    Message.Location.inbox.labelID.rawValue,
                    customLabel.rawValue
                ].sorted()
                XCTAssertEqual(labelIDs, expectationLabelIDs)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            ex.fulfill()
        }
        await fulfillment(of: [ex, apiIsCalled], timeout: 2)
    }

    func testLabelConversation_addAnExistingCustomLabel_shouldNotAddMoreLabel() async throws {
        let customLabel = LabelID(String.randomString(6))
        let conversationID = try await mockConversation(customLabelID: customLabel)
        let ex = expectation(description: "Label finish")
        let apiIsCalled = expectation(description: "Api is called")

        mockApiService.requestJSONStub.bodyIs { _, method, path, body, _, _, _, _, _, _, _, _, completion in
            defer { apiIsCalled.fulfill() }
            XCTAssertEqual(method, .put)
            XCTAssertEqual(path, "/mail/v4/conversations/label")
            guard
                let bodyDict = body as? [String: Any],
                let ids = bodyDict["IDs"] as? [String],
                let labelID = bodyDict["LabelID"] as? String
            else {
                XCTFail("Can't get expected data")
                return
            }
            XCTAssertEqual(ids, [conversationID.rawValue])
            XCTAssertEqual(labelID, customLabel.rawValue)
            completion(nil, .success([:]))
        }

        sut.label(
            conversationIDs: [conversationID],
            as: customLabel
        ) { result in
            switch result {
            case .success:
                let labelIDs = self.sortedLabelIDs(from: conversationID)
                let expectationLabelIDs = [
                    Message.Location.inbox.labelID.rawValue,
                    customLabel.rawValue
                ].sorted()
                XCTAssertEqual(labelIDs, expectationLabelIDs)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            ex.fulfill()
        }
        await fulfillment(of: [ex, apiIsCalled], timeout: 2)
    }

    func testUnLabelConversation_theLabelShouldBeRemoved() async throws {
        let customLabel = LabelID(String.randomString(6))
        let conversationID = try await mockConversation(customLabelID: customLabel)
        let ex = expectation(description: "UnLabel finish")
        let apiIsCalled = expectation(description: "Api is called")

        mockApiService.requestJSONStub.bodyIs { _, method, path, body, _, _, _, _, _, _, _, _, completion in
            defer { apiIsCalled.fulfill() }
            XCTAssertEqual(method, .put)
            XCTAssertEqual(path, "/mail/v4/conversations/unlabel")
            guard
                let bodyDict = body as? [String: Any],
                let ids = bodyDict["IDs"] as? [String],
                let labelID = bodyDict["LabelID"] as? String
            else {
                XCTFail("Can't get expected data")
                return
            }
            XCTAssertEqual(ids, [conversationID.rawValue])
            XCTAssertEqual(labelID, customLabel.rawValue)
            completion(nil, .success([:]))
        }

        sut.unlabel(conversationIDs: [conversationID], as: customLabel) { result in
            switch result {
            case .success:
                let labelIDs = self.sortedLabelIDs(from: conversationID)
                let expectationLabelIDs = [Message.Location.inbox.labelID.rawValue]
                XCTAssertEqual(labelIDs, expectationLabelIDs)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            ex.fulfill()
        }
        await fulfillment(of: [ex, apiIsCalled], timeout: 2)
    }

    func testUnLabelConversation_ifTheLabelDoesNotExist() async throws {
        let customLabel = LabelID(String.randomString(6))
        let conversationID = try await mockConversation(customLabelID: customLabel)
        let anotherLabel = LabelID(String.randomString(6))
        let ex = expectation(description: "UnLabel finish")
        let apiIsCalled = expectation(description: "Api is called")

        mockApiService.requestJSONStub.bodyIs { _, method, path, body, _, _, _, _, _, _, _, _, completion in
            defer { apiIsCalled.fulfill() }
            XCTAssertEqual(method, .put)
            XCTAssertEqual(path, "/mail/v4/conversations/unlabel")
            guard
                let bodyDict = body as? [String: Any],
                let ids = bodyDict["IDs"] as? [String],
                let labelID = bodyDict["LabelID"] as? String
            else {
                XCTFail("Can't get expected data")
                return
            }
            XCTAssertEqual(ids, [conversationID.rawValue])
            XCTAssertEqual(labelID, anotherLabel.rawValue)
            completion(nil, .success([:]))
        }

        sut.unlabel(conversationIDs: [conversationID], as: anotherLabel) { result in
            switch result {
            case .success:
                let labelIDs = self.sortedLabelIDs(from: conversationID)
                let expectationLabelIDs = [
                    Message.Location.inbox.labelID.rawValue,
                    customLabel.rawValue
                ].sorted()
                XCTAssertEqual(labelIDs, expectationLabelIDs)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            ex.fulfill()
        }
        await fulfillment(of: [ex, apiIsCalled], timeout: 2)
    }

    func testMoveConversation_moveInboxToArchive_shouldSuccess() async throws {
        let conversationID = try await mockConversation()
        let ex = expectation(description: "UnLabel finish")
        let apiIsCalled = expectation(description: "Api is called")

        mockApiService.requestJSONStub.bodyIs { _, method, path, body, _, _, _, _, _, _, _, _, completion in
            defer { apiIsCalled.fulfill() }
            XCTAssertEqual(method, .put)
            XCTAssertEqual(path, "/mail/v4/conversations/label")
            guard
                let bodyDict = body as? [String: Any],
                let ids = bodyDict["IDs"] as? [String],
                let labelID = bodyDict["LabelID"] as? String
            else {
                XCTFail("Can't get expected data")
                return
            }
            XCTAssertEqual(ids, [conversationID.rawValue])
            XCTAssertEqual(labelID, Message.Location.archive.rawValue)
            completion(nil, .success([:]))
        }

        sut.move(
            conversationIDs: [conversationID],
            from: Message.Location.inbox.labelID,
            to: Message.Location.archive.labelID,
            callOrigin: nil
        ) { result in
            switch result {
            case .success:
                let labelIDs = self.sortedLabelIDs(from: conversationID)
                let expectationLabelIDs = [Message.Location.archive.labelID.rawValue]
                XCTAssertEqual(labelIDs, expectationLabelIDs)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            ex.fulfill()
        }
        await fulfillment(of: [ex, apiIsCalled], timeout: 2)
    }

    func testMoveConversation_moveInboxToInbox_theInboxLabelShouldExist() async throws {
        let conversationID = try await mockConversation()
        let ex = expectation(description: "UnLabel finish")
        let apiIsCalled = expectation(description: "Api is called")
        apiIsCalled.isInverted = true

        mockApiService.requestJSONStub.bodyIs { _, method, path, body, _, _, _, _, _, _, _, _, completion in
            apiIsCalled.fulfill()
        }

        sut.move(
            conversationIDs: [conversationID],
            from: Message.Location.inbox.labelID,
            to: Message.Location.inbox.labelID,
            callOrigin: nil
        ) { result in
            switch result {
            case .success:
                let labelIDs = self.sortedLabelIDs(from: conversationID)
                let expectationLabelIDs = [Message.Location.inbox.labelID.rawValue]
                XCTAssertEqual(labelIDs, expectationLabelIDs)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            ex.fulfill()
        }
        await fulfillment(of: [ex, apiIsCalled], timeout: 1)
    }
}

extension ConversationDataServiceProxyTest {
    private func mockConversation(
        labelID: LabelID = Message.Location.inbox.labelID,
        customLabelID: LabelID? = nil
    ) async throws -> ConversationID {
        try await globalContainer.contextProvider.writeAsync { context in
            let conversation = Conversation(context: context)
            conversation.conversationID = UUID().uuidString
            conversation.numMessages = 5

            let contextLabel = ContextLabel(context: context)
            contextLabel.labelID = labelID.rawValue
            contextLabel.conversation = conversation
            contextLabel.unreadCount = 0
            contextLabel.userID = self.userID
            contextLabel.conversationID = conversation.conversationID

            if let customLabelID {
                let customLabel = ContextLabel(context: context)
                customLabel.labelID = customLabelID.rawValue
                customLabel.conversation = conversation
                customLabel.unreadCount = 0
                customLabel.userID = self.userID
                customLabel.conversationID = conversation.conversationID
            }
            return ConversationID(conversation.conversationID)
        }
    }

    private func sortedLabelIDs(from conversationID: ConversationID) -> [String] {
        globalContainer.contextProvider.read { context in
            guard
                let conversation = Conversation.conversationForConversationID(
                    conversationID.rawValue,
                    inManagedObjectContext: context
                ),
                let labels = conversation.labels.allObjects as? [ContextLabel]
            else {
                XCTFail("Can't get expected data")
                return []
            }
            return labels.map(\.labelID).sorted()
        }
    }
}
