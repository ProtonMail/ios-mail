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

import Groot
import XCTest
@testable import ProtonMail
import ProtonCoreTestingToolkitUnitTestsServices

final class FetchMessageDetailTests: XCTestCase {
    private var queueManager: MockQueueManager!
    private var apiService: APIServiceMock!
    private var contextProvider: MockCoreDataContextProvider!
    private var sut: FetchMessageDetail!

    override func setUpWithError() throws {
        try super.setUpWithError()
        queueManager = MockQueueManager()
        apiService = APIServiceMock()
        contextProvider = MockCoreDataContextProvider()
        sut = FetchMessageDetail(
            dependencies: .init(queueManager: queueManager,
                                apiService: apiService,
                                contextProvider: contextProvider)
        )
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        queueManager = nil
        apiService = nil
        contextProvider = nil
        sut = nil
    }

    private func prepareTestData(modifiedData: [String: Any]) throws -> Message {
        let testData = try XCTUnwrap(testMessageDetailData.parseObjectAny())
        var responseData = ["Message": testData]
        for (key, value) in modifiedData {
            responseData["Message"]?[key] = value
        }

        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            guard path.starts(with: "/mail/v4/messages") else { return }
            completion(nil, .success(responseData))
        }
        let context = contextProvider.viewContext
        guard let message = try GRTJSONSerialization.object(
            withEntityName: Message.Attributes.entityName,
            fromJSONDictionary: testData,
            in: context
        ) as? Message else {
            XCTFail("Should be a Message")
            return Message()
        }
        _ = context.saveUpstreamIfNeeded()
        return message
    }

    func testBasicHasToBeQueued_Ignore() throws {
        let data = ["Body": "response body"]
        let message = try XCTUnwrap(prepareTestData(modifiedData: data))
        let expectation = expectation(description: "Closure is called")
        let params = FetchMessageDetail.Params(
            message: MessageEntity(message),
            hasToBeQueued: true,
            ignoreDownloaded: true
        )
        sut.execute(params: params) { result in
            switch result {
            case .success(let entity):
                XCTAssertTrue(entity.isDetailDownloaded)
                XCTAssertTrue(entity.hasMetaData)
                XCTAssertFalse(entity.unRead)
                XCTAssertEqual(entity.body, "response body")
            case .failure(let error):
                XCTFail("Shouldn't have error \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertEqual(queueManager.executeTimes, 1)
    }

    func testLocalIsNewer_notInQueue_NotIgnore() throws {
        let data: [String: Any] = ["Time": 1325279399,
                                   "Body": "response body"]
        let message = try XCTUnwrap(prepareTestData(modifiedData: data))
        message.isDetailDownloaded = true
        let expectation = expectation(description: "Closure is called")
        let params = FetchMessageDetail.Params(
            message: MessageEntity(message),
            hasToBeQueued: false,
            ignoreDownloaded: false
        )
        sut.execute(params: params) { result in
            switch result {
            case .success(let entity):
                let body = "-----BEGIN PGP MESSAGE-----This is encrypted body-----END PGP MESSAGE-----"
                XCTAssertEqual(entity.body, body)
            case .failure(let error):
                XCTFail("Shouldn't have error \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertEqual(queueManager.executeTimes, 0)
    }

    func testNewAttachmentInResponseHasToBeQueued_Ignore() throws {
        let data = ["Attachments": [
            [
                "ID": "response_attach",
                "Name": "test.mp3",
                "Size": 200,
                "MIMEType": "audio/mpeg",
                "Disposition": "attachment",
                "KeyPackets": "aaa",
                "SignatureKeyPackets": nil,
                "Headers": [
                    "content-disposition": "attachment",
                    "x-pm-content-encryption": "end-to-end"
                ],
                "Signature": "-----BEGIN PGP ",
                "EncSignature": "-----BEGIN PGP "
            ]
        ]
        ]
        let message = try XCTUnwrap(prepareTestData(modifiedData: data))
        // Local has 3 attachments, one attachment is uploading
        // Response only has one attachment
        // 2 local attachments are deleted by other client
        let localAttachment = try XCTUnwrap(message.attachments.allObjects as? [Attachment])
        localAttachment.first?.attachmentID = "0"
        let expectation = expectation(description: "Closure is called")
        let params = FetchMessageDetail.Params(
            message: MessageEntity(message),
            hasToBeQueued: true,
            ignoreDownloaded: true
        )
        sut.execute(params: params) { result in
            switch result {
            case .success(let entity):
                XCTAssertEqual(entity.attachments.count, 2)
                XCTAssertEqual(entity.numAttachments, 2)
            case .failure(let error):
                XCTFail("Shouldn't have error \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertEqual(queueManager.executeTimes, 1)
    }
}
