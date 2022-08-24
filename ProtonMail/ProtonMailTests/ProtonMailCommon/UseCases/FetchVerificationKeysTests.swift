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

import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_TestingToolkit
import XCTest

@testable import ProtonMail

class FetchVerificationKeysTests: XCTestCase {
    private var sut: FetchVerificationKeys!
    private var contactProviderMock: MockContactProvider!
    private var emailPublicKeysProviderMock: EmailPublicKeysProviderMock!
    private var validKey: Key!
    private var invalidKey: Key!

    private let contactEmail = "someone@example.com"

    private var dependencies: FetchVerificationKeys.Dependencies {
        FetchVerificationKeys.Dependencies(
            contactProvider: contactProviderMock,
            emailPublicKeysProvider: emailPublicKeysProviderMock
        )
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        contactProviderMock = MockContactProvider()

        emailPublicKeysProviderMock = EmailPublicKeysProviderMock()

        let validKeyPair = try MailCrypto.generateRandomKeyPair()
        validKey = Key(keyID: "good", privateKey: validKeyPair.privateKey)
        validKey.flags.insert(.verificationEnabled)

        let invalidKeyPair = try MailCrypto.generateRandomKeyPair()
        invalidKey = Key(keyID: "bad", privateKey: invalidKeyPair.privateKey)

        sut = FetchVerificationKeys(dependencies: dependencies, userAddresses: [])
    }

    override func tearDownWithError() throws {
        sut = nil
        contactProviderMock = nil
        emailPublicKeysProviderMock = nil
        validKey = nil
        invalidKey = nil

        try super.tearDownWithError()
    }

    func testFetchesUsersOwnNonCompromisedKeysIfEmailBelongsToTheUser() throws {
        let userAddress = Address(
            addressID: "",
            domainID: nil,
            email: "user@example.com",
            send: .active,
            receive: .active,
            status: .enabled,
            type: .externalAddress,
            order: 1,
            displayName: "",
            signature: "a",
            hasKeys: 1,
            keys: [validKey, invalidKey]
        )
        sut = FetchVerificationKeys(dependencies: dependencies, userAddresses: [userAddress])

        let validKeyData = try XCTUnwrap(validKey.publicKey.unArmor)

        let expectation = XCTestExpectation()

        sut.execute(email: userAddress.email) { result in
            switch result {
            case .success(let keys):
                XCTAssertEqual(keys, [validKeyData])
                expectation.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testFetchesContactsNonCompromisedKeysIfEmailDoesNotBelongToTheUser() throws {
        let keys: [Key] = [invalidKey, validKey]

        try stubContact(with: keys)

        let keysResponse = KeysResponse()
        keysResponse.keys = keys.map {
            KeyResponse(flags: $0.flags, publicKey: $0.publicKey)
        }
        emailPublicKeysProviderMock.stubbedResult = .success([contactEmail: keysResponse])

        let validKeyData = try XCTUnwrap(validKey.publicKey.unArmor)

        let expectation = XCTestExpectation()

        sut.execute(email: contactEmail) { result in
            switch result {
            case .success(let keys):
                XCTAssertEqual(keys, [validKeyData])
                expectation.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testReturnsEmptyListIfNoContactsAreFound() {
        let expectation = XCTestExpectation()

        sut.execute(email: contactEmail) { result in
            switch result {
            case .success(let keys):
                XCTAssert(keys.isEmpty)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testIgnoresMalformedContactKeys() throws {
        let malformedKey = try Crypto.random(byte: 256)
        let publicKeys: [Data] = [
            malformedKey,
            try XCTUnwrap(validKey.publicKey.unArmor)
        ]

        stubContact(with: publicKeys)

        let keysResponse = KeysResponse()
        keysResponse.keys = [
            KeyResponse(flags: [.verificationEnabled], publicKey: malformedKey.base64EncodedString()),
            KeyResponse(flags: [.verificationEnabled], publicKey: validKey.publicKey)
        ]
        emailPublicKeysProviderMock.stubbedResult = .success([contactEmail: KeysResponse()])

        let validKeyData = try XCTUnwrap(validKey.publicKey.unArmor)

        let expectation = XCTestExpectation()

        sut.execute(email: contactEmail) { result in
            switch result {
            case .success(let keys):
                XCTAssertEqual(keys, [validKeyData])
                expectation.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testPropagatesProviderFailures() {
        let stubbedError = NSError.badResponse()
        contactProviderMock.stubbedFetchResult = .failure(stubbedError)

        let expectation = XCTestExpectation()

        sut.execute(email: contactEmail) { result in
            switch result {
            case .success:
                XCTFail("The result should not be success since the fetch is set as failed")
            case .failure(let error as NSError):
                XCTAssertEqual(error, stubbedError)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    private func stubContact(with publicKeys: [Data]) {
        let stubbedContacts = [
            PreContact(
                email: contactEmail,
                pubKey: publicKeys.first,
                pubKeys: publicKeys,
                sign: false,
                encrypt: false,
                mime: false,
                plainText: false
            )
        ]
        contactProviderMock.stubbedFetchResult = .success(stubbedContacts)
    }

    private func stubContact(with keys: [Key]) throws {
        let publicKeys: [Data] = try keys.map {
            try XCTUnwrap($0.publicKey.unArmor)
        }

        stubContact(with: publicKeys)
    }
}
