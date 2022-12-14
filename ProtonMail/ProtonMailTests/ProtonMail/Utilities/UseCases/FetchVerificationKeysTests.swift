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
    private var mockFetchAndVerifyContacts: MockFetchAndVerifyContacts!
    private var mockFetchEmailAddressesPublicKey: MockFetchEmailAddressesPublicKey!
    private var validKey: Key!
    private var invalidKey: Key!

    private let contactEmail = "someone@example.com"

    private var dependencies: FetchVerificationKeys.Dependencies {
        FetchVerificationKeys.Dependencies(
            fetchAndVerifyContacts: mockFetchAndVerifyContacts,
            fetchEmailsPublicKeys: mockFetchEmailAddressesPublicKey
        )
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockFetchAndVerifyContacts = MockFetchAndVerifyContacts()
        mockFetchEmailAddressesPublicKey = MockFetchEmailAddressesPublicKey()

        let validKeyPair = try MailCrypto.generateRandomKeyPair()
        validKey = Key(keyID: "good", privateKey: validKeyPair.privateKey)
        validKey.flags.insert(.verificationEnabled)

        let invalidKeyPair = try MailCrypto.generateRandomKeyPair()
        invalidKey = Key(keyID: "bad", privateKey: invalidKeyPair.privateKey)

        sut = FetchVerificationKeys(dependencies: dependencies, userAddresses: [])
    }

    override func tearDownWithError() throws {
        sut = nil
        mockFetchAndVerifyContacts = nil
        mockFetchEmailAddressesPublicKey = nil
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

        sut.execute(params: .init(email: userAddress.email)) { result in
            switch result {
            case .success(let (keys, keysResponse)):
                assertEquals(keys, [validKeyData])
                XCTAssertNil(keysResponse)
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
        mockFetchEmailAddressesPublicKey.result = .success([contactEmail: keysResponse])

        let validKeyData = try XCTUnwrap(validKey.publicKey.unArmor)

        let expectation = XCTestExpectation()

        sut.execute(params: .init(email: contactEmail)) { result in
            switch result {
            case .success(let (keys, keysResponse)):
                assertEquals(keys, [validKeyData])
                XCTAssertNotNil(keysResponse)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        wait(for: [expectation], timeout: 2)
    }

    func testReturnsEmptyListIfNoContactsAreFound() {
        let expectation = XCTestExpectation()
        mockFetchEmailAddressesPublicKey.result = .success([contactEmail : KeysResponse()])

        sut.execute(params: .init(email: contactEmail)) { result in
            switch result {
            case .success(let (keys, keysResponse)):
                XCTAssert(keys.isEmpty)
                XCTAssertNil(keysResponse)
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
        mockFetchEmailAddressesPublicKey.result = .success([contactEmail: KeysResponse()])

        let validKeyData = try XCTUnwrap(validKey.publicKey.unArmor)

        let expectation = XCTestExpectation()

        sut.execute(params: .init(email: contactEmail)) { result in
            switch result {
            case .success(let (keys, keysResponse)):
                assertEquals(keys, [validKeyData])
                XCTAssertNotNil(keysResponse)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    private func stubContact(with publicKeys: [Data]) {
        let stubbedContacts = [
            PreContact(
                email: contactEmail,
                pubKeys: publicKeys,
                sign: false,
                encrypt: false,
                scheme: nil,
                mimeType: nil
            )
        ]
        mockFetchAndVerifyContacts.result = .success(stubbedContacts)
    }

    private func stubContact(with keys: [Key]) throws {
        let publicKeys: [Data] = try keys.map {
            try XCTUnwrap($0.publicKey.unArmor)
        }

        stubContact(with: publicKeys)
    }
}

// Armored keys need to be unarmored first and only the raw data compared.
// This is because the Version header, Comments etc are not always in the same order, so a comparison might fail
// even though the actual key data is the same.
private func assertEquals(_ lhs: [ArmoredKey], _ rhs: [Data], file: StaticString = #file, line: UInt = #line) {
    let lhsData: [Data]
    do {
        lhsData = try lhs.map { try $0.unArmor().value }
    } catch {
        XCTFail("\(error)", file: file, line: line)
        return
    }

    XCTAssertEqual(lhsData, rhs, file: file, line: line)
}
