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

import ProtonCoreKeymaker
@testable import ProtonMail
import XCTest

final class UpdateMobileSignatureUseCaseTests: XCTestCase {
    private var sut: UpdateMobileSignature!
    private var cacheMock: MockMobileSignatureCacheProtocol!
    private var testContainer: TestContainer!

    private var coreKeyMaker: KeyMakerProtocol {
        testContainer.keyMaker
    }

    override func setUp() {
        super.setUp()
        cacheMock = MockMobileSignatureCacheProtocol()

        testContainer = .init()

        sut = .init(dependencies: .init(
            coreKeyMaker: coreKeyMaker,
            cache: cacheMock,
            keychain: testContainer.keychain
        ))
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        cacheMock = nil
        testContainer = nil
    }

    func testExecute_signatureIsSavedToCache() throws {
        let signature = String.randomString(20)
        let userID = String.randomString(10)
        let e = expectation(description: "Closure is called.")
        let mainKey = try XCTUnwrap(coreKeyMaker.mainKey(by: testContainer.keychain.randomPinProtection))

        sut.execute(
            params: .init(signature: signature, userID: .init(userID))) { result in
                switch result {
                case .success():
                    break
                case .failure:
                    XCTFail("Should not return error")
                }
                e.fulfill()
            }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(cacheMock.setEncryptedMobileSignatureStub.wasCalledExactlyOnce)
        let savedUserID = cacheMock.setEncryptedMobileSignatureStub.lastArguments?.a1
        XCTAssertEqual(savedUserID, userID)
        let savedData = try XCTUnwrap(cacheMock.setEncryptedMobileSignatureStub.lastArguments?.a2)
        let unlockedData = try Locked<String>(encryptedValue: savedData).unlock(with: mainKey)
        XCTAssertEqual(unlockedData, signature)
    }
}
