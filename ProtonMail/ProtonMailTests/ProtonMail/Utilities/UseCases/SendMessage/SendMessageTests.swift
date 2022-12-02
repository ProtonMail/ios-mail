// Copyright (c) 2022 Proton Technologies AG
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

import Foundation
import Groot
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

final class SendMessageTests: XCTestCase {
    private var sut: SendMessage!

    private var mockApiService: APIServiceMock!
    private var mockPrepareSendMetadata: MockPrepareSendMetadata!
    private var mockPrepareSendRequest: MockPrepareSendRequest!

    private let dummyMessageURI = "dummy_uri"
    private lazy var dummyParams: SendMessage.Params = {
        SendMessage.Params(
            messageObjectURI: dummyMessageURI,
            scheduleSendDeliveryTime: nil,
            undoSendDelay: 0
        )
    }()
    private let nsError = NSError(domain: "", code: -15)
    private let waitTimeout = 2.0

    override func setUp() {
        super.tearDown()
        mockApiService = APIServiceMock()
        mockPrepareSendMetadata = MockPrepareSendMetadata()
        mockPrepareSendRequest = MockPrepareSendRequest()
        sut = makeSUT()
    }

    override func tearDown() {
        super.tearDown()
        mockApiService = nil
        mockPrepareSendMetadata = nil
        mockPrepareSendRequest = nil
        sut = nil
    }

    func testExecute_whenEverythingSucceeds_itReturnsVoid() {
        mockApiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            if path.contains("/messages/") {
                completion(nil, .success(["Code": 1000]))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(NSError.badParameter([])))
            }
        }

        let expectation = expectation(description: "")
        sut.execute(params: dummyParams) { result in
            XCTAssert(try! result.get() == Void())
            expectation.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testExecute_whenPrepareMetadataFails_itReturnsTheMetadataError() {
        let metadataError: PrepareSendMessageMetadataError = [
            PrepareSendMessageMetadataError.noMessageFoundForURI,
            PrepareSendMessageMetadataError.decryptBodyFail
        ].randomElement()!
        mockPrepareSendMetadata.failureResult = metadataError

        let expectation = expectation(description: "")
        sut.execute(params: dummyParams) { result in
            switch result {
            case .failure(let returnedError as PrepareSendMessageMetadataError):
                XCTAssert(returnedError == metadataError)
            default:
                XCTFail("expected a PrepareSendMessageMetadataError as the result")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testExecute_whenPrepareRequestFails_itReturnsThePrepareRequestError() {
        let error = MessageSendingRequestBuilder.BuilderError.sessionKeyFailedToCreate
        mockPrepareSendRequest.failureResult = error

        let expectation = expectation(description: "")
        sut.execute(params: dummyParams) { result in
            switch result {
            case .failure(let returnedError as MessageSendingRequestBuilder.BuilderError):
                XCTAssert(returnedError == error)
            default:
                XCTFail("expected a MessageSendingRequestBuilder.BuilderError as the result")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testExecute_whenSendRequestFails_itReturnsTheAPIError() {
        mockApiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            completion(nil, .failure(self.nsError))
        }

        let expectation = expectation(description: "")
        sut.execute(params: dummyParams) { result in
            switch result {
            case .failure(let error as ResponseError):
                XCTAssert(error.underlyingError?.code == self.nsError.code)
            default:
                XCTFail("expected a ResponseError as the result")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }
}

extension SendMessageTests {

    private func makeSUT() -> SendMessage {
        let sendMessageDependencies: SendMessage.Dependencies = .init(
            prepareSendMetadata: mockPrepareSendMetadata,
            prepareSendRequest: mockPrepareSendRequest,
            apiService: mockApiService,
            userDataSource: makeUserManager(apiMock: mockApiService)
        )
        return SendMessage(dependencies: sendMessageDependencies)
    }

    private func makeUserManager(apiMock: APIServiceMock) -> UserManager {
        let keyPair = try! MailCrypto.generateRandomKeyPair()
        let key = Key(keyID: "1", privateKey: keyPair.privateKey)
        key.signature = "signature is needed to make this a V2 key"
        let address = Address(
            addressID: "",
            domainID: nil,
            email: "",
            send: .active,
            receive: .active,
            status: .enabled,
            type: .externalAddress,
            order: 1,
            displayName: "",
            signature: "a",
            hasKeys: 1,
            keys: [key]
        )

        let user = UserManager(api: apiMock, role: .member)
        user.userInfo.userAddresses = [address]
        user.userInfo.userKeys = [key]
        user.authCredential.mailboxpassword = keyPair.passphrase
        return user
    }
}
