// Copyright (c) 2022 Proton AG
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
import PromiseKit
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_TestingToolkit
@testable import ProtonMail

class MockMessageDataService: MessageDataServiceProtocol {
    var messageDecrypter: MessageDecrypterProtocol {
        return mockDecrypter
    }
    var mockDecrypter: MessageDecrypterMock!

    var pushNotificationMessageID: String? = "pushNotificationID"
    var hasValidEventID = true

    private let response: [String: Any] = try! JSONSerialization
        .jsonObject(with: Data(testFetchingMessagesDataInInbox.utf8), options: []) as! [String: Any]

    private(set) var wasFetchMessagesCountCalled: Bool = false

    var fetchMessagesReturnError: Bool = false
    var fetchMessagesCountReturnEmpty: Bool = false
    var mockMessage: Message?
    var messageSendingDataResult: MessageSendingData!

    func fetchMessages(labelID: LabelID, endTime: Int, fetchUnread: Bool, completion: @escaping (_ task: URLSessionDataTask?, _ result: Swift.Result<JSONDictionary, ResponseError>) -> Void) {
        if fetchMessagesReturnError {
            let error = ResponseError(httpCode: 500, responseCode: nil, userFacingMessage: nil, underlyingError: nil)
            completion(nil, .failure(error))
        } else {
            completion(nil, .success(response))
        }
    }

    func fetchMessagesCount(completion: @escaping (MessageCountResponse) -> Void) {
        wasFetchMessagesCountCalled = true
        let response = MessageCountResponse()
        if !fetchMessagesCountReturnEmpty {
            response.counts = [
                ["LabelID": 0, "Total": 38, "Unread": 3],
                ["LabelID": 1, "Total": 5, "Unread": 0]
            ]
        }
        completion(response)
    }

    @FuncStub(MockMessageDataService.fetchMessageMetaData(messageIDs:completion:)) var callFetchMessageMetaData
    func fetchMessageMetaData(messageIDs: [MessageID], completion: @escaping (FetchMessagesByIDResponse) -> Void) {
        callFetchMessageMetaData(messageIDs, completion)

        var parsedObject = testMessageMetaData.parseObjectAny() ?? [:]
        parsedObject["ID"] = messageIDs.first?.rawValue ?? UUID().uuidString
        let responseDict = ["Messages": [parsedObject]]
        let response = FetchMessagesByIDResponse()
        _ = response.ParseResponse(responseDict)
        completion(response)
    }

    func isEventIDValid() -> Bool { self.hasValidEventID }

    func idsOfMessagesBeingSent() -> [String] {
        []
    }

    func getMessageSendingData(for uri: String) -> ProtonMail.MessageSendingData? {
        return messageSendingDataResult
    }

    @FuncStub(MockMessageDataService.updateMessageAfterSend(message:sendResponse:completionQueue:completion:)) var callUpdateMessageAfterSend
    func updateMessageAfterSend(
        message: MessageEntity,
        sendResponse: JSONDictionary,
        completionQueue: DispatchQueue,
        completion: @escaping () -> Void
    ) {
        callUpdateMessageAfterSend(message, sendResponse, completionQueue, completion)
        completion()
    }

    func messageWithLocation(recipientList: String,
                             bccList: String,
                             ccList: String,
                             title: String,
                             encryptionPassword: String,
                             passwordHint: String,
                             expirationTimeInterval: TimeInterval,
                             body: String,
                             attachments: [Any]?,
                             mailbox_pwd: Passphrase,
                             sendAddress: Address,
                             inManagedObjectContext context: NSManagedObjectContext) -> Message {
        return mockMessage ?? Message()
    }

    @FuncStub(MockMessageDataService.saveDraft) var callSaveDraft
    func saveDraft(_ message: Message?) {
        callSaveDraft(message)
    }

    @FuncStub(MockMessageDataService.updateMessage) var callUpdateMessage
    func updateMessage(_ message: Message,
                       expirationTimeInterval: TimeInterval,
                       body: String,
                       mailbox_pwd: Passphrase) {
        callUpdateMessage(message, expirationTimeInterval, body, mailbox_pwd)
    }

    @FuncStub(MockMessageDataService.mark, initialReturn: false) var callMark
    func mark(messageObjectIDs: [NSManagedObjectID], labelID: LabelID, unRead: Bool) -> Bool {
        return callMark(messageObjectIDs, labelID, unRead)
    }

    @FuncStub(MockMessageDataService.updateAttKeyPacket) var callUpdateAttKeyPacket
    func updateAttKeyPacket(message: MessageEntity, addressID: String) {
        callUpdateAttKeyPacket(message, addressID)
    }

    @FuncStub(MockMessageDataService.delete, initialReturn: Promise()) var callDelete
    func delete(att: AttachmentEntity, messageID: MessageID) -> Promise<Void> {
        return callDelete(att, messageID)
    }

    @FuncStub(MockMessageDataService.upload) var callUpload
    func upload(att: Attachment) {
        callUpload(att)
    }
}

final class MockMessageDataAction: MessageDataActionProtocol {
    func mark(messageObjectIDs: [NSManagedObjectID], labelID: LabelID, unRead: Bool) -> Bool {
        return true
    }
}
