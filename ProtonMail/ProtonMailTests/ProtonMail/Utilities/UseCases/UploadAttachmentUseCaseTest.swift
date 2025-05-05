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
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest
@testable import ProtonMail

final class UploadAttachmentUseCaseTest: XCTestCase {
    private var sut: UploadAttachment!
    private var user: UserManager!
    private var apiService: APIServiceMock!
    private var messageDataService: MockMessageDataService!
    private var contextProvider: MockCoreDataContextProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()
        apiService = APIServiceMock()
        messageDataService = MockMessageDataService()
        contextProvider = MockCoreDataContextProvider()
        user = try UserManager.prepareUser(apiMock: apiService)
        sut = UploadAttachment(dependencies: .init(messageDataService: messageDataService, user: user))
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        contextProvider = nil
        sut = nil
        user = nil
        apiService = nil
        messageDataService = nil
    }

    func testExecute_cannotFindAttachment_shouldReturnResourceDoesNotExist() async throws {
        do {
            try await sut.execute(attachmentURI: "123")
            XCTFail("Shouldn't success")
        } catch {
            let uploadError = try XCTUnwrap(error as? UploadAttachment.UploadAttachmentError)
            XCTAssertEqual(uploadError, .attachmentDoesNotExist("123"))
        }
    }

    func testExecute_cannotFindMessage_shouldThrowError() async throws {
        let (_, attachments) = try mockMessageAndAttachment(isPublicKey: false, hasDuplicatedAttachment: false)
        let attachment = try XCTUnwrap(attachments.first)
        messageDataService.getAttachmentEntityStub.bodyIs { _, _ in
            attachment
        }
        messageDataService.getMessageEntityStub.bodyIs { _, _ in
            throw NSError(domain: "proton.ch", code: -1)
        }
        do {
            try await sut.execute(attachmentURI: attachment.objectID.rawValue.uriRepresentation().absoluteString)
            XCTFail("Shouldn't success")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(-1, nsError.code)
        }
    }
// TODO: enable test when using Xcode 14.3+
//    func testExecute_uploadDuplicatedAttachment_shouldRemoveDuplicatedAttachment_andThrowError() async throws {
//        let (message, attachments) = try mockMessageAndAttachment(isPublicKey: false, hasDuplicatedAttachment: true)
//        let uploadedAttachment = try XCTUnwrap(attachments.first)
//        let duplicatedAttachment = try XCTUnwrap(attachments.last)
//        let ex = expectation(description: "duplicated attachment is removed")
//        messageDataService.getAttachmentEntityStub.bodyIs { _, uri in
//            if uri == uploadedAttachment.objectID.rawValue.uriRepresentation().absoluteString {
//                return uploadedAttachment
//            } else {
//                return duplicatedAttachment
//            }
//        }
//        messageDataService.getMessageEntityStub.bodyIs { _, _ in
//            message
//        }
//        messageDataService.removeAttachmentFromDBStub.bodyIs { _, objectIDs in
//            XCTAssertEqual(objectIDs, [duplicatedAttachment.objectID])
//            ex.fulfill()
//        }
//        messageDataService.messageSendingDataResult = .init(
//            message: message,
//            cachedUserInfo: nil,
//            cachedAuthCredential: nil,
//            cachedSenderAddress: user.userInfo.userAddresses.first,
//            cachedPassphrase: nil,
//            defaultSenderAddress: nil
//        )
//        do {
//            let duplicatedURI = duplicatedAttachment.objectID.rawValue.uriRepresentation().absoluteString
//            try await sut.execute(attachmentURI: duplicatedURI)
//        } catch {
//            let uploadError = try XCTUnwrap(error as? UploadAttachment.UploadAttachmentError)
//            XCTAssertEqual(uploadError, .duplicatedUploading)
//        }
//        await fulfillment(of: [ex])
//    }

    func testExecute_uploadingOneAttachment_shouldSuccess() async throws {
        let (message, attachments) = try mockMessageAndAttachment(isPublicKey: false, hasDuplicatedAttachment: false)
        let attachment = try XCTUnwrap(attachments.first)
        messageDataService.getAttachmentEntityStub.bodyIs { _, _ in
            attachment
        }
        messageDataService.getMessageEntityStub.bodyIs { _, _ in
            message
        }
        messageDataService.messageSendingDataResult = .init(
            message: message,
            cachedUserInfo: nil,
            cachedAuthCredential: nil,
            cachedSenderAddress: user.userInfo.userAddresses.first,
            cachedPassphrase: nil,
            defaultSenderAddress: nil
        )
        messageDataService.updateAttachmentStub.bodyIs { _, uploadingResponse, objectID in
            XCTAssertEqual(objectID, attachment.objectID)
            let apiResponse = uploadingResponse.response
            guard let result = apiResponse["result"] as? Bool,
                  result == true else {
                XCTFail("Should have expected response")
                return
            }

        }
        apiService.uploadFromFileJsonStub.bodyIs { _, path, parameters, keyPacket, dataPacketSourceFileURL, signature, _, _, _, _, _, _, _, completion in
            XCTAssertEqual(path, "/mail/v4/attachments")
            guard
                parameters["Disposition"] != nil,
                let contentID = parameters["ContentID"],
                let messageID = parameters["MessageID"],
                let fileName = parameters["Filename"],
                let mimeType = parameters["MIMEType"]
            else {
                XCTFail("Should have above values")
                return
            }
            XCTAssertEqual(contentID, attachment.getContentID())
            XCTAssertEqual(messageID, message.messageID.rawValue)
            XCTAssertEqual(fileName, attachment.name)
            XCTAssertEqual(mimeType, attachment.rawMimeType)
            completion(nil, .success(["result": true]))
        }
        try await sut.execute(attachmentURI: attachment.objectID.rawValue.uriRepresentation().absoluteString)
    }

//    func testExecute_uploadPublicKeyFailed_shouldNotThrowError_andPublicKeyShouldBeRemoved() async throws {
//        let (message, attachments) = try mockMessageAndAttachment(isPublicKey: true, hasDuplicatedAttachment: false)
//        let attachment = try XCTUnwrap(attachments.first)
//        let ex = expectation(description: "PublicKey is removed")
//        messageDataService.getAttachmentEntityStub.bodyIs { _, _ in
//            attachment
//        }
//        messageDataService.getMessageEntityStub.bodyIs { _, _ in
//            message
//        }
//        messageDataService.messageSendingDataResult = .init(
//            message: message,
//            cachedUserInfo: nil,
//            cachedAuthCredential: nil,
//            cachedSenderAddress: user.userInfo.userAddresses.first,
//            cachedPassphrase: nil,
//            defaultSenderAddress: nil
//        )
//        messageDataService.removeAttachmentFromDBStub.bodyIs { _, objectIDs in
//            XCTAssertEqual(objectIDs, [attachment.objectID])
//            ex.fulfill()
//        }
//        apiService.uploadFromFileJsonStub.bodyIs { _, path, parameters, keyPacket, dataPacketSourceFileURL, signature, _, _, _, _, _, _, completion in
//            XCTAssertEqual(path, "/mail/v4/attachments")
//            completion(nil, .failure(.badResponse()))
//        }
//        try await sut.execute(attachmentURI: attachment.objectID.rawValue.uriRepresentation().absoluteString)
//        await fulfillment(of: [ex])
//    }

//    func testExecute_uploadFailedWithExpectedError_shouldPostNotification_andTheAttachmentShouldBeRemoved() async throws {
//        let (message, attachments) = try mockMessageAndAttachment(isPublicKey: false, hasDuplicatedAttachment: false)
//        let attachment = try XCTUnwrap(attachments.first)
//        let ex = expectation(description: "Attachment is removed")
//        messageDataService.getAttachmentEntityStub.bodyIs { _, _ in
//            attachment
//        }
//        messageDataService.getMessageEntityStub.bodyIs { _, _ in
//            message
//        }
//        messageDataService.removeAttachmentFromDBStub.bodyIs { _, objectIDs in
//            XCTAssertEqual(objectIDs, [attachment.objectID])
//            ex.fulfill()
//        }
//        messageDataService.messageSendingDataResult = .init(
//            message: message,
//            cachedUserInfo: nil,
//            cachedAuthCredential: nil,
//            cachedSenderAddress: user.userInfo.userAddresses.first,
//            cachedPassphrase: nil,
//            defaultSenderAddress: nil
//        )
//        apiService.uploadFromFileJsonStub.bodyIs { _, path, parameters, keyPacket, dataPacketSourceFileURL, signature, _, _, _, _, _, _, completion in
//            XCTAssertEqual(path, "/mail/v4/attachments")
//            completion(nil, .failure(NSError(domain: "pm.test", code: 2024)))
//        }
//        let notificationEX = expectation(forNotification: .attachmentUploadFailed, object: nil) { notification in
//            guard let errorCode = notification.userInfo?["code"] as? Int else {
//                XCTFail("Should have error code")
//                return false
//            }
//            XCTAssertEqual(errorCode, 2024)
//            return true
//        }
//        do {
//            try await sut.execute(attachmentURI: attachment.objectID.rawValue.uriRepresentation().absoluteString)
//        } catch {
//            let nsError = error as NSError
//            XCTAssertEqual(nsError.code, 2024)
//        }
//        await fulfillment(of: [ex, notificationEX])
//    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

extension UploadAttachmentUseCaseTest {
    private func mockMessageAndAttachment(
        isPublicKey: Bool,
        hasDuplicatedAttachment: Bool
    ) throws -> (MessageEntity, [AttachmentEntity]) {
        try contextProvider.performAndWaitOnRootSavingContext { context in
            let message = Message(context: context)
            let messageID = String.randomString(10)
            message.messageID = messageID
            let attachment = self.mockAttachment(
                context: context,
                message: message,
                contentID: nil,
                isPublicKey: isPublicKey,
                isUploaded: hasDuplicatedAttachment
            )
            var attachments = [AttachmentEntity(attachment)]
            if hasDuplicatedAttachment {
                let duplicated = self.mockAttachment(
                    context: context,
                    message: message,
                    contentID: attachment.contentID(),
                    isPublicKey: isPublicKey,
                    isUploaded: false
                )
                attachments.append(AttachmentEntity(duplicated))
            }
            return (MessageEntity(message), attachments)
        }
    }

    private func mockAttachment(
        context: NSManagedObjectContext,
        message: Message,
        contentID: String?,
        isPublicKey: Bool,
        isUploaded: Bool
    ) -> Attachment {
        let attachment = Attachment(context: context)
        attachment.attachmentID = isUploaded ? String.randomString(3) : "0"
        attachment.fileName = isPublicKey ? "publicKey - abc@pm.test - 0xaa.asc" : String.randomString(6)
        attachment.mimeType = "image/jpeg"
        attachment.message = message
        let contentID = contentID ?? UUID().uuidString
        attachment.headerInfo = "{ \"content-disposition\": \"attachment\",  \"content-id\": \"\(contentID)\" }"
        try? attachment.writeToLocalURL(data: Data("123".utf8))
        return attachment
    }
}
