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
import XCTest
@testable import ProtonMail

final class UnSnoozeUseCaseTests: XCTestCase {
    private var apiService: APIServiceMock!
    private var sut: UnSnooze!

    override func setUpWithError() throws {
        try super.setUpWithError()
        apiService = APIServiceMock()
        sut = UnSnooze(dependencies: .init(apiService: apiService))
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        apiService = nil
        sut = nil
    }

    func testUnSnooze_successCase() async throws {
        let id = UUID().uuidString
        apiService.requestDecodableStub.bodyIs { _, method, path, body, _, _, _, _, _, _, _, completion in
            XCTAssertEqual(method, .put)
            XCTAssertEqual(path, "/mail/v4/conversations/unsnooze")

            guard
                let bodyDict = body as? [String: [String]],
                let requestIDs = bodyDict["IDs"]
            else {
                XCTFail("Should have ids")
                return
            }
            XCTAssertEqual(requestIDs, [id])
            guard let response = try? self.mockSuccessResponse() else {
                XCTFail("Should have response")
                return
            }
            completion(nil, .success(response))
        }

        try await sut.execute(conversationID: ConversationID(id))
    }

    func testUnSnooze_partialFailureCase_throwErrorInResponse() async throws {
        let errorString = String.randomString(9)
        apiService.requestDecodableStub.bodyIs { _, method, path, body, _, _, _, _, _, _, _, completion in
            guard let response = try? self.mockPartialFailureResponse(errorMessage: errorString) else {
                XCTFail("Should have response")
                return
            }
            completion(nil, .success(response))
        }

        do {
            try await sut.execute(conversationID: ConversationID("id"))
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(error.localizedDescription, errorString)
        }
    }

    func testUnSnooze_failureCase() async throws {
        let errorString = "Attribute IDs[0] is invalid: The data is not a valid ID."
        apiService.requestDecodableStub.bodyIs { _, method, path, body, _, _, _, _, _, _, _, completion in
            completion(nil, .failure(self.mockFailureError()))
        }

        do {
            try await sut.execute(conversationID: ConversationID("id"))
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(error.localizedDescription, errorString)
        }
    }
}

extension UnSnoozeUseCaseTests {
    private func mockSuccessResponse() throws -> GeneralMultipleResponse {
        let json: [String: Any] = [
            "code": 1001,
            "responses": [
                [
                    "ID": UUID().uuidString,
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

    private func mockPartialFailureResponse(errorMessage: String) throws -> GeneralMultipleResponse {
        let json: [String: Any] = [
            "code": 1001,
            "responses": [
                [
                    "ID": UUID().uuidString,
                    "response": [
                        "code": 123,
                        "error": errorMessage
                    ]
                ]
            ]
        ]
        let data = try json.serializedToData()
        let res = try JSONDecoder().decode(GeneralMultipleResponse.self, from: data)
        return res
    }

    private func mockFailureError() -> NSError {
        NSError(.init(
            code: 2001,
            error: "Attribute IDs[0] is invalid: The data is not a valid ID.",
            errorDescription: "")
        )
    }
}
