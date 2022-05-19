// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

@testable import ProtonMail
import ProtonCore_TestingToolkit
import ProtonCore_Services

class MockMessageDataService: MessageDataServiceProtocol {
    private let response: [String: Any] = try! JSONSerialization
        .jsonObject(with: Data(testFetchingMessagesDataInInbox.utf8), options: []) as! [String: Any]

    private(set) var wasFetchMessagesCountCalled: Bool = false

    var fetchMessagesReturnError: Bool = false
    var fetchMessagesCountReturnEmpty: Bool = false

    func fetchMessages(labelID: LabelID, endTime: Int, fetchUnread: Bool, completion: CompletionBlock?) {
        if fetchMessagesReturnError {
            completion?(nil, nil, NSError.badParameter(nil))
        } else {
            completion?(nil, response, nil)
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
}

