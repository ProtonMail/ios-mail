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
import ProtonCoreNetworking
import ProtonCoreTestingToolkitUnitTestsServices

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

    func testExecute_whenOneEmailIsPassed_andRequestSucceeds() async throws {
        let dummyEmail = "dummy@email"
        let flagsValue = 3
        let response = PublicKeysResponseTestData.successTestResponse(flags: flagsValue, publicKey: dummyPublicKey)

        mockApiServer.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                completion(nil, .success(response))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.badResponse()))
            }
        }
        let publicKeysDict = try await sut.execute(emails: [dummyEmail])
            XCTAssert(Array(publicKeysDict.keys) == [dummyEmail])
            XCTAssert(publicKeysDict[dummyEmail]!.keys[0].flags.rawValue == flagsValue)
            XCTAssert(publicKeysDict[dummyEmail]!.keys[0].publicKey == self.dummyPublicKey)
    }

    func testExecute_whenOneEmailIsPassed_andRequestFails() async throws {
        mockApiServer.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .failure(self.nsError))
        }

        do {
            _ = try await sut.execute(emails: [""])
            XCTFail("expected an error")
        } catch let error as ResponseError {
            XCTAssert(error.underlyingError?.code == self.nsError.code)
        } catch {
            XCTFail("expected a ResponseError as the result")
        }
    }

    func testExecute_whenThereAreDuplicatedEmails_requestsForDuplicatedEmailsAreOnlySentOnce() async throws {
        let dummyEmails = ["dummy@email", "different@email", "dummy@email"]
        let response = PublicKeysResponseTestData.successTestResponse(flags: 3, publicKey: dummyPublicKey)

        mockApiServer.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success(response))
        }
        
        _ = try await sut.execute(emails: dummyEmails)
        XCTAssertEqual(self.mockApiServer.requestJSONStub.callCounter, 2)
    }

    func testExecute_whenMultipleEmailsArePassed_andAllRequestSucceed() async throws {
        let dummyEmails = ["email+1", "email+2", "email+3"]
        let responses = [1, 2, 3].map {
            PublicKeysResponseTestData.successTestResponse(flags: $0, publicKey: dummyPublicKey)
        }

        mockApiServer.requestJSONStub.bodyIs { _, _, path, query, _, _, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let email: String = (query as! [String: Any])["Email"] as! String
                let index = Int(String(email.last!))!
                // return responses in different order
                let dispatchTime: DispatchTime = .now() + [0, 0.1, 0.15].randomElement()!
                DispatchQueue.global().asyncAfter(deadline: dispatchTime) {
                    completion(nil, .success(responses[index-1]))
                }
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.badResponse()))
            }
        }

        let publicKeysDict = try await sut.execute(emails: dummyEmails)
        [1, 2, 3].forEach { value in
            XCTAssert(publicKeysDict["email+\(value)"]!.keys[0].flags.rawValue == value)
        }
    }

    func testExecute_whenMultipleEmailsArePassed_andOneFails()  async throws {
        let dummyEmails = ["email+1", "email+2", "email+3"]
        let responses = [1, 2, 3].map {
            PublicKeysResponseTestData.successTestResponse(flags: $0, publicKey: dummyPublicKey)
        }

        mockApiServer.requestJSONStub.bodyIs { _, _, path, query, _, _, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                let email: String = (query as! [String: Any])["Email"] as! String
                let index = Int(String(email.last!))!
                // return responses in different order
                let dispatchTime: DispatchTime = .now() + [0, 0.1, 0.15].randomElement()!
                DispatchQueue.global().asyncAfter(deadline: dispatchTime) {
                    if email == "email+2" {
                        completion(nil, .failure(self.nsError))
                    } else {
                        completion(nil, .success(responses[index-1]))
                    }
                }
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.badResponse()))
            }
        }

        do {
            _ = try await sut.execute(emails: dummyEmails)
            XCTFail("expected an error")
        } catch let error as ResponseError {
            XCTAssert(error.underlyingError?.code == self.nsError.code)
        } catch {
            XCTFail("expected a ResponseError as the result")
        }
    }
}
