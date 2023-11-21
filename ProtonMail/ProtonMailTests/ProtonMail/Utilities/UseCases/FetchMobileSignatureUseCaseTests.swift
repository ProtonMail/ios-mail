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

final class FetchMobileSignatureUseCaseTests: XCTestCase {
    private var sut: FetchMobileSignature!
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

    func testExecute_whenNoDataStoreInCache_withPaidUser_returnDefaultSignature() {
        cacheMock.getEncryptedMobileSignatureStub.bodyIs { _, _ in
            return nil
        }

        let signature = sut.execute(params: .init(userID: "", isPaidUser: true))

        XCTAssertEqual(signature, Constants.defaultMobileSignature)
        XCTAssertTrue(cacheMock.removeEncryptedMobileSignatureStub.wasCalledExactlyOnce)
    }

    func testExecute_whenNoDataStoreInCache_withNotPaidUser_returnDefaultSignature() {
        cacheMock.getEncryptedMobileSignatureStub.bodyIs { _, _ in
            return nil
        }

        let signature = sut.execute(params: .init(userID: "", isPaidUser: false))

        XCTAssertEqual(signature, Constants.defaultMobileSignature)

        XCTAssertTrue(cacheMock.removeEncryptedMobileSignatureStub.wasCalledExactlyOnce)
    }

    func testExecute_withDataStoreInCache_withPaidUser_returnStoredSignature() throws {
        let signature = String.randomString(20)
        let mainKey = try XCTUnwrap(coreKeyMaker.mainKey(by: testContainer.keychain.randomPinProtection))
        let encryptedData = try Locked<String>(clearValue: signature, with: mainKey).encryptedValue
        cacheMock.getEncryptedMobileSignatureStub.bodyIs { _, _ in
            return encryptedData
        }

        let result = sut.execute(params: .init(userID: "", isPaidUser: true))

        XCTAssertEqual(result, signature)
        XCTAssertTrue(cacheMock.removeEncryptedMobileSignatureStub.wasNotCalled)
    }

    func testExecute_withDataStoreInCache_withNoPaidUser_returnDefaultSignature() throws {
        let signature = String.randomString(20)
        let mainKey = try XCTUnwrap(coreKeyMaker.mainKey(by: testContainer.keychain.randomPinProtection))
        let encryptedData = try Locked<String>(clearValue: signature, with: mainKey).encryptedValue
        cacheMock.getEncryptedMobileSignatureStub.bodyIs { _, _ in
            return encryptedData
        }

        let result = sut.execute(params: .init(userID: "", isPaidUser: false))

        XCTAssertEqual(result, Constants.defaultMobileSignature)
        XCTAssertTrue(cacheMock.removeEncryptedMobileSignatureStub.wasCalledExactlyOnce)
    }
}
