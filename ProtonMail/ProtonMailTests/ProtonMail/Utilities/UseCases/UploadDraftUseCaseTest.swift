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
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest
@testable import ProtonMail

final class UploadDraftUseCaseTest: XCTestCase {
    private var sut: UploadDraft!
    private var coreDataService: MockCoreDataContextProvider!
    private var messageDataService: MockMessageDataService!
    private var apiService: APIServiceMock!

    private var mockAddressID: String!
    private var sender: Sender!
    private let toList = "[{\"Address\":\"receiver@pm.me\",\"Name\":\"aName\"}]"

    override func setUpWithError() throws {
        mockAddressID = String.randomString(9)
        apiService = .init()
        coreDataService = .init()
        messageDataService = .init()
        sender = try SenderMock.mock(isProton: 1, isSimpleLogin: 0, shouldDisplaySenderImage: 0, bimiSelector: nil)
        sut = .init(
            dependencies: .init(
                apiService: apiService,
                coreDataService: coreDataService,
                messageDataService: messageDataService
            )
        )
    }

    override func tearDownWithError() throws {
        mockAddressID = nil
        apiService = nil
        sender = nil
        coreDataService = nil
        messageDataService = nil
        sut = nil
    }

    func testExecute_whenResourceDoesNotExist_throwResourceDoesNotExist() async throws {
        let fakeID = String.randomString(6)
        do {
            try await sut.execute(messageObjectID: fakeID)
            XCTFail("Should throw error")
        } catch {
            let receivedError = try XCTUnwrap(error as? UploadDraft.UploadDraftError)
            XCTAssertEqual(receivedError, .messageNotFoundForURI(fakeID))
        }
    }

    func testExecute_apiError() async throws {
        let (mockMessage, mockEntity) = try makeMessage()
        let objectID = mockMessage.objectID.uriRepresentation().absoluteString
        let error = NSError(domain: "test.pm", code: 999)
        stubAPI(expectedMethod: .post, expectedPath: "/mail/v4/messages", response: nil, error: error)
        stubUserAddress()
        messageDataService.messageSendingDataResult = .init(
            message: mockEntity,
            cachedUserInfo: nil,
            cachedAuthCredential: nil,
            cachedSenderAddress: nil,
            cachedPassphrase: nil,
            defaultSenderAddress: nil
        )
        do {
            try await sut.execute(messageObjectID: objectID)
            XCTFail("Should throw error")
        } catch {
            let receivedError = try XCTUnwrap(error as? ResponseError)
            XCTAssertEqual(receivedError.underlyingError?.code, 999)
        }
    }

    func testExecute_storageExceededError() async throws {
        let (mockMessage, mockEntity) = try makeMessage()
        let objectID = mockMessage.objectID.uriRepresentation().absoluteString
        let error = NSError(domain: "test.pm", code: 2011)
        stubAPI(expectedMethod: .post, expectedPath: "/mail/v4/messages", response: nil, error: error)
        stubUserAddress()
        messageDataService.messageSendingDataResult = .init(
            message: mockEntity,
            cachedUserInfo: nil,
            cachedAuthCredential: nil,
            cachedSenderAddress: nil,
            cachedPassphrase: nil,
            defaultSenderAddress: nil
        )
        do {
            try await sut.execute(messageObjectID: objectID)
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(messageDataService.deleteMessageStub.callCounter, 1)
        }
    }

    func testExecute_createForwardDraftWithAttachments_shouldUpdateID() async throws {
        let keyPackets = Array(0...3).map { _ in return String.randomString(8) }
        let (mockMessage, mockEntity) = try makeMessage(attachmentKeyPackets: keyPackets)
        let objectID = mockMessage.objectID
        let objectIDString = mockMessage.objectID.uriRepresentation().absoluteString
        let (messageID, conversationID, subject, response) = DraftTestData.mockCreateDraftResponse(
            addressID: mockAddressID,
            attachmentKeyPackets: keyPackets,
            sender: sender
        )
        stubAPI(expectedMethod: .post, expectedPath: "/mail/v4/messages", response: response, error: nil)
        stubUserAddress()
        messageDataService.messageSendingDataResult = .init(
            message: mockEntity,
            cachedUserInfo: nil,
            cachedAuthCredential: nil,
            cachedSenderAddress: nil,
            cachedPassphrase: nil,
            defaultSenderAddress: nil
        )

        try await sut.execute(messageObjectID: objectIDString)
        try coreDataService.performAndWaitOnRootSavingContext { context in
            guard let message = try context.existingObject(with: objectID) as? Message else {
                XCTFail("Should have message")
                return
            }
            XCTAssertEqual(message.messageID, messageID)
            XCTAssertEqual(message.conversationID, conversationID)
            XCTAssertEqual(message.title, subject)

            guard let attachments = message.attachments.allObjects as? [Attachment] else {
                XCTFail("Should have attachments")
                return
            }
            XCTAssertEqual(attachments.count, 4)
            for attachment in attachments {
                guard let keyPacket = attachment.keyPacket,
                      keyPackets.contains(keyPacket) else {
                    XCTFail("Should have keyPacket")
                    return
                }
                XCTAssertNotEqual(attachment.attachmentID, "unknown")
            }
        }
    }

    func testExecute_updateDraft_shouldUpdateDate() async throws {
        let messageID = String.randomString(8)
        let (mockMessage, mockEntity) = try makeMessage(isDownloaded: true, messageID: messageID)
        let objectID = mockMessage.objectID
        let objectIDString = mockMessage.objectID.uriRepresentation().absoluteString
        let date = Date(timeIntervalSince1970: 88)

        let (_, conversationID, subject, response) = DraftTestData.mockCreateDraftResponse(
            messageID: messageID,
            addressID: mockAddressID,
            time: date,
            sender: sender
        )
        stubAPI(expectedMethod: .put, expectedPath: "/mail/v4/messages/\(messageID)", response: response, error: nil)
        stubUserAddress()
        messageDataService.messageSendingDataResult = .init(
            message: mockEntity,
            cachedUserInfo: nil,
            cachedAuthCredential: nil,
            cachedSenderAddress: nil,
            cachedPassphrase: nil,
            defaultSenderAddress: nil
        )

        try await sut.execute(messageObjectID: objectIDString)
        try coreDataService.performAndWaitOnRootSavingContext { context in
            guard let message = try context.existingObject(with: objectID) as? Message else {
                XCTFail("Should have message")
                return
            }
            XCTAssertEqual(message.messageID, messageID)
            XCTAssertEqual(message.conversationID, conversationID)
            XCTAssertEqual(message.title, subject)
            XCTAssertEqual(message.time, date)
        }
    }
}

extension UploadDraftUseCaseTest {
    private func makeMessage(
        attachmentKeyPackets: [String] = [],
        isDownloaded: Bool = false,
        messageID: String? = nil
    ) throws -> (Message, MessageEntity) {
        return try coreDataService.performAndWaitOnRootSavingContext { context in
            let message = Message(context: context)
            if let messageID = messageID {
                message.messageID = messageID
            }
            message.isDetailDownloaded = isDownloaded
            message.title = "subject"
            message.body = "body"
            message.addressID = mockAddressID
            message.toList = toList
            message.attachments = NSSet(array: mockAttachments(keyPackets: attachmentKeyPackets, context: context))
            _ = context.saveUpstreamIfNeeded()
            return (message, MessageEntity(message))
        }
    }

    private func mockAttachments(keyPackets: [String], context: NSManagedObjectContext) -> [Attachment] {
        keyPackets.map { keyPacket in
            let attachment = Attachment(context: context)
            attachment.attachmentID = "unknown"
            attachment.keyPacket = keyPacket
            return attachment
        }
    }

    private func stubAPI(expectedMethod: HTTPMethod, expectedPath: String, response: [String: Any]?, error: NSError?) {
        apiService.requestJSONStub.bodyIs { _, method, path, body, _, _, _, _, _, _, _, _, completion in
            XCTAssertEqual(method, expectedMethod)
            XCTAssertEqual(path, expectedPath)
            guard
                let bodyDict = body as? [String: Any],
                let requestBody = bodyDict["Message"] as? [String: Any]
            else {
                XCTFail("Parse request body failed")
                return
            }
            XCTAssertEqual(requestBody["Subject"] as? String, "subject")
            XCTAssertEqual(requestBody["Body"] as? String, "body")
            XCTAssertEqual(requestBody["Subject"] as? String, "subject")
            XCTAssertEqual(requestBody["Unread"] as? Int, 1)
            guard let senderDict = requestBody["Sender"] as? [String: String] else {
                XCTFail("Parse sender failed")
                return
            }
            XCTAssertEqual(senderDict["Name"], "I am a tester")
            XCTAssertEqual(senderDict["Address"], "tester@pm.me")
            guard let toList = requestBody["ToList"] as? [[String: String]] else {
                XCTFail("Parse toList failed")
                return
            }
            XCTAssertEqual(toList.first?["Name"], "aName")
            XCTAssertEqual(toList.first?["Address"], "receiver@pm.me")
            if let error = error {
                completion(nil, .failure(error))
            } else if let response = response {
                completion(nil, .success(response))
            } else {
                XCTFail("Config error")
            }
        }
    }

    private func stubUserAddress() {
        messageDataService.userAddressStub.bodyIs { _, addressID in
            XCTAssertEqual(addressID.rawValue, self.mockAddressID)
            return Address(
                addressID: addressID.rawValue,
                domainID: nil,
                email: "tester@pm.me",
                send: .active,
                receive: .active,
                status: .enabled,
                type: .protonDomain,
                order: 0,
                displayName: "I am a tester",
                signature: "signature",
                hasKeys: 0,
                keys: []
            )
        }
    }
}
