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

@testable import ProtonMail
import XCTest
import ProtonCore_TestingToolkit

final class FetchEmailAddressesPublicKeyTests: XCTestCase {
    var sut: FetchEmailAddressesPublicKey!

    private var mockApiServer: APIServiceMock!
    private let nsError = NSError(domain: "", code: -10)
    private let dummyPublicKey = "dummy string"

    override func setUp() {
        mockApiServer = APIServiceMock()
        let dependencies = FetchEmailAddressesPublicKey.Dependencies(apiService: mockApiServer)
        sut = FetchEmailAddressesPublicKey(dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockApiServer = nil
    }

    func testExecute_whenOneEmailIsPassed_andRequestSucceeds() {
        let expectation = expectation(description: "returns the correct dictionary")

        let dummyEmail = "dummy@email"
        let flagsValue = 3
        let response = PublicKeysResponseTestData.successTestResponse(flags: flagsValue, publicKey: dummyPublicKey)

        mockApiServer.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                completion?(nil, response, nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        sut.execute(params: .init(emails:[dummyEmail])) { [unowned self] result in
            let publicKeysDict: [String: KeysResponse] = try! result.get()
            XCTAssert(Array(publicKeysDict.keys) == [dummyEmail])
            XCTAssert(publicKeysDict[dummyEmail]!.keys[0].flags.rawValue == flagsValue)
            XCTAssert(publicKeysDict[dummyEmail]!.keys[0].publicKey == self.dummyPublicKey)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenOneEmailIsPassed_andRequestFails() {
        let expectation = expectation(description: "returns the request error")

        mockApiServer.requestStub.bodyIs { _, _, _, _, _, _, _, _, _, completion in
            completion?(nil, nil, self.nsError)
        }
        sut.execute(params: .init(emails:[""])) { [unowned self] result in
            switch result {
            case .success:
                XCTFail("expected an error as the result")
            case .failure(let error):
                XCTAssert((error as NSError).code == self.nsError.code)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenThereAreDuplicatedEmails_requestsForDuplicatedEmailsAreOnlySentOnce() {
        let expectation = expectation(description: "duplicated emails requests are only sent once")

        let dummyEmails = ["dummy@email", "different@email", "dummy@email"]
        let response = PublicKeysResponseTestData.successTestResponse(flags: 3, publicKey: dummyPublicKey)

        mockApiServer.requestStub.bodyIs { _, _, _, _, _, _, _, _, _, completion in
            completion?(nil, response, nil)
        }
        sut.execute(params: .init(emails:dummyEmails)) { [unowned self]  _ in
            XCTAssertTrue(self.mockApiServer.requestStub.callCounter == 2)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenMultipleEmailsArePassed_andAllRequestSucceed() {
        let expectation = expectation(description: "returns the correct dictionary")

        let dummyEmails = ["email+1", "email+2", "email+3"]
        let responses = [1, 2, 3].map {
            PublicKeysResponseTestData.successTestResponse(flags: $0, publicKey: dummyPublicKey)
        }

        mockApiServer.requestStub.bodyIs { _, _, path, query, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let email: String = (query as! [String: Any])["Email"] as! String
                let index = Int(String(email.last!))!
                // return responses in different order
                let dispatchTime: DispatchTime = .now() + [0, 0.1, 0.15].randomElement()!
                DispatchQueue.global().asyncAfter(deadline: dispatchTime) {
                    completion?(nil, responses[index-1], nil)
                }
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        sut.execute(params: .init(emails:dummyEmails)) { result in
            let publicKeysDict: [String: KeysResponse] = try! result.get()
            [1, 2, 3].forEach { value in
                XCTAssert(publicKeysDict["email+\(value)"]!.keys[0].flags.rawValue == value)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testExecute_whenMultipleEmailsArePassed_andOneFails() {
        let expectation = expectation(description: "returns the request error")

        let dummyEmails = ["email+1", "email+2", "email+3"]
        let responses = [1, 2, 3].map {
            PublicKeysResponseTestData.successTestResponse(flags: $0, publicKey: dummyPublicKey)
        }

        mockApiServer.requestStub.bodyIs { _, _, path, query, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let email: String = (query as! [String: Any])["Email"] as! String
                let index = Int(String(email.last!))!
                // return responses in different order
                let dispatchTime: DispatchTime = .now() + [0, 0.1, 0.15].randomElement()!
                DispatchQueue.global().asyncAfter(deadline: dispatchTime) {
                    if email == "email+2" {
                        completion?(nil, nil, self.nsError)
                    } else {
                        completion?(nil, responses[index-1], nil)
                    }
                }
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        sut.execute(params: .init(emails:dummyEmails)) { [unowned self] result in
            switch result {
            case .success:
                XCTFail("expected an error as the result")
            case .failure(let error):
                XCTAssert((error as NSError).code == self.nsError.code)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }
}
