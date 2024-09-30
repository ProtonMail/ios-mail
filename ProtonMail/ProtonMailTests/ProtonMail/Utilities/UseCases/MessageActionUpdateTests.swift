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

import XCTest
import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail

final class MessageActionUpdateTests: XCTestCase {
    private var sut: MessageActionUpdate!
    private var apiService: APIServiceMock!
    private var contextProvider: MockCoreDataContextProvider!

    override func setUpWithError() throws {
        apiService = APIServiceMock()
        contextProvider = MockCoreDataContextProvider()
        sut = MessageActionUpdate(dependencies: .init(apiService: apiService, contextProvider: contextProvider))
    }

    override func tearDownWithError() throws {
        sut = nil
        apiService = nil
        contextProvider = nil
    }

    func testExecute_whenMessageListIsEmpty_shouldReturn() async throws {
        apiService.requestDecodableStub.bodyIs { _, _, path, body, _, _, _, _, _, _, _, completion in
            XCTFail("Shouldn't call API")
            completion(nil, .failure(NSError(domain: "test.com", code: -999)))
        }
        try await sut.execute(ids: .left([]), action: .read)
    }

    func testExecute_giveMessageID_successCase() async throws {
        let (_, ids) = try prepareMessages()
        apiService.requestDecodableStub.bodyIs { _, _, path, body, _, _, _, _, _, _, _, completion in
            XCTAssertEqual(path, "/mail/v4/messages/delete")
            guard
                let bodyDict = body as? [String: [String]],
                let requestIDs = bodyDict["IDs"]
            else {
                XCTFail("Should have ids")
                return
            }
            XCTAssertEqual(requestIDs, ids)
            guard let response = try? self.mockSuccessResponse() else {
                XCTFail("Should have response")
                return
            }
            completion(nil, .success(response))
        }
        let messageIDs = ids.map(MessageID.init(rawValue:))
        try await sut.execute(ids: .right(messageIDs), action: .delete)
    }

    func testExecute_giveMessageURI_successCase() async throws {
        let (uris, ids) = try prepareMessages()
        apiService.requestDecodableStub.bodyIs { _, _, path, body, _, _, _, _, _, _, _, completion in
            XCTAssertEqual(path, "/mail/v4/messages/read")
            guard
                let bodyDict = body as? [String: [String]],
                let requestIDs = bodyDict["IDs"]
            else {
                XCTFail("Should have ids")
                return
            }
            XCTAssertEqual(requestIDs, ids)
            guard let response = try? self.mockSuccessResponse() else {
                XCTFail("Should have response")
                return
            }
            completion(nil, .success(response))
        }
        try await sut.execute(ids: .left(uris), action: .read)
    }

    func testExecute_getResourceDoesNotExistCode_shouldTreatAsSuccess() async throws {
        let (_, ids) = try prepareMessages()
        apiService.requestDecodableStub.bodyIs { _, _, path, body, _, _, _, _, _, _, _, completion in
            XCTAssertEqual(path, "/mail/v4/messages/delete")
            guard
                let bodyDict = body as? [String: [String]],
                let requestIDs = bodyDict["IDs"]
            else {
                XCTFail("Should have ids")
                return
            }
            XCTAssertEqual(requestIDs, ids)
            guard let response = try? self.mockFailureResponse(errorCode: 2501) else {
                XCTFail("Should have response")
                return
            }
            completion(nil, .success(response))
        }
        let messageIDs = ids.map(MessageID.init(rawValue:))
        try await sut.execute(ids: .right(messageIDs), action: .delete)
    }

    func testExecute_getError_shouldThrowError() async throws {
        let (_, ids) = try prepareMessages()
        apiService.requestDecodableStub.bodyIs { _, _, path, body, _, _, _, _, _, _, _, completion in
            XCTAssertEqual(path, "/mail/v4/messages/delete")
            guard
                let bodyDict = body as? [String: [String]],
                let requestIDs = bodyDict["IDs"]
            else {
                XCTFail("Should have ids")
                return
            }
            XCTAssertEqual(requestIDs, ids)
            guard let response = try? self.mockFailureResponse(errorCode: 17392) else {
                XCTFail("Should have response")
                return
            }
            completion(nil, .success(response))
        }
        let messageIDs = ids.map(MessageID.init(rawValue:))
        do {
            try await sut.execute(ids: .right(messageIDs), action: .delete)
        } catch {
            XCTAssertEqual(error.localizedDescription, "some error message")
        }
    }

    /// - Returns: ([message uri], [messageID])
    private func prepareMessages(num: Int = 3) throws -> ([String], [String]) {
        var messageIDs: [String] = []
        var messageURIs: [String] = []
        try contextProvider.write { context in
            for _ in 0..<num {
                let message = Message(context: context)
                let messageID = String.randomString(8)
                message.messageID = messageID
                messageIDs.append(messageID)

                try? context.obtainPermanentIDs(for: [message])
                let uri = message.objectID.uriRepresentation().absoluteString
                messageURIs.append(uri)
            }
        }
        return (messageURIs, messageIDs)
    }

    private func mockSuccessResponse() throws -> GeneralMultipleResponse {
        let json: [String: Any] = [
            "code": 1001,
            "responses": [
                [
                    "ID": "kZ03Eun7JRHM",
                    "response": [
                        "code": 1000
                    ]
                ]
            ]
        ]
        let data = try json.serializedToData()
        let res = try JSONDecoder().decode(GeneralMultipleResponse.self, from: data)
        return res
    }

    private func mockFailureResponse(errorCode: Int) throws -> GeneralMultipleResponse {
        let json: [String: Any] = [
            "code": 1001,
            "responses": [
                [
                    "ID": "kZ03Eun7JRHMeCVaRXo",
                    "response": [
                        "code": errorCode,
                        "error": "some error message"
                    ]
                ]
            ]
        ]
        let data = try json.serializedToData()
        let res = try JSONDecoder().decode(GeneralMultipleResponse.self, from: data)
        return res
    }
}
