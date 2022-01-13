// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail
@testable import ProtonCore_DataModel

final class UpdatePrivateKeyRequestTests: XCTestCase {
    var sut: UpdatePrivateKeyRequest!
    let updatedKey = Key(keyID: String.randomString(8),
                         privateKey: String.randomString(8),
                         keyFlags: 0,
                         token: String.randomString(8),
                         signature: String.randomString(8),
                         activation: nil,
                         active: 1,
                         version: 1,
                         primary: 1,
                         isUpdated: true)
    let nonUpdatedKey = Key(keyID: String.randomString(8),
                            privateKey: String.randomString(8),
                            keyFlags: 0,
                            token: String.randomString(8),
                            signature: String.randomString(8),
                            activation: nil,
                            active: 1,
                            version: 1,
                            primary: 1,
                            isUpdated: false)

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testUserLevelKeysShouldIncludeOnlyUpdatedOnes() throws {
        sut = UpdatePrivateKeyRequest(clientEphemeral: String.randomString(8),
                                      clientProof: String.randomString(8),
                                      SRPSession: String.randomString(8),
                                      keySalt: String.randomString(8),
                                      userlevelKeys: [updatedKey, nonUpdatedKey],
                                      addressKeys: [],
                                      tfaCode: nil,
                                      orgKey: nil,
                                      userKeys: nil,
                                      auth: nil,
                                      authCredential: nil)
        let producedKeys = sut.parameters?["Keys"] as? [[String: String]]
        let userLevelsKey = try XCTUnwrap(producedKeys)
        XCTAssertTrue(userLevelsKey.contains(where: { $0.contains(where: { $0.key == "ID" && $0.value == updatedKey.keyID })}))
        XCTAssertTrue(userLevelsKey.contains(where: { $0.contains(where: { $0.key == "PrivateKey" && $0.value == updatedKey.privateKey })}))
        XCTAssertFalse(userLevelsKey.contains(where: { $0.contains(where: { $0.key == "ID" && $0.value == nonUpdatedKey.keyID })}))
        XCTAssertFalse(userLevelsKey.contains(where: { $0.contains(where: { $0.key == "PrivateKey" && $0.value == nonUpdatedKey.privateKey })}))
    }

    func testAddressKeysShouldIncludeOnlyUpdatedOnes() throws {
        let address = Address(addressID: String.randomString(8), domainID: nil, email: String.randomString(8), send: .active, receive: .active, status: .enabled, type: .protonDomain, order: 1, displayName: String.randomString(8), signature: String.randomString(8), hasKeys: 1, keys: [updatedKey, nonUpdatedKey])
        sut = UpdatePrivateKeyRequest(clientEphemeral: String.randomString(8),
                                      clientProof: String.randomString(8),
                                      SRPSession: String.randomString(8),
                                      keySalt: String.randomString(8),
                                      userlevelKeys: [],
                                      addressKeys: [address].toKeys(),
                                      tfaCode: nil,
                                      orgKey: nil,
                                      userKeys: [],
                                      auth: nil,
                                      authCredential: nil)
        let producedKeys = sut.parameters?["Keys"] as? [[String: String]]
        let userLevelsKey = try XCTUnwrap(producedKeys)
        XCTAssertTrue(userLevelsKey.contains(where: { $0.contains(where: { $0.key == "ID" && $0.value == updatedKey.keyID })}))
        XCTAssertTrue(userLevelsKey.contains(where: { $0.contains(where: { $0.key == "PrivateKey" && $0.value == updatedKey.privateKey })}))
        XCTAssertFalse(userLevelsKey.contains(where: { $0.contains(where: { $0.key == "ID" && $0.value == nonUpdatedKey.keyID })}))
        XCTAssertFalse(userLevelsKey.contains(where: { $0.contains(where: { $0.key == "PrivateKey" && $0.value == nonUpdatedKey.privateKey })}))
    }

    func testUserKeysShouldIncludeOnlyUpdatedOnes() throws {
        sut = UpdatePrivateKeyRequest(clientEphemeral: String.randomString(8),
                                      clientProof: String.randomString(8),
                                      SRPSession: String.randomString(8),
                                      keySalt: String.randomString(8),
                                      userlevelKeys: [],
                                      addressKeys: [],
                                      tfaCode: nil,
                                      orgKey: nil,
                                      userKeys: [updatedKey, nonUpdatedKey],
                                      auth: nil,
                                      authCredential: nil)
        let producedKeys = sut.parameters?["UserKeys"] as? [[String: String]]
        let userLevelsKey = try XCTUnwrap(producedKeys)
        XCTAssertTrue(userLevelsKey.contains(where: { $0.contains(where: { $0.key == "ID" && $0.value == updatedKey.keyID })}))
        XCTAssertTrue(userLevelsKey.contains(where: { $0.contains(where: { $0.key == "PrivateKey" && $0.value == updatedKey.privateKey })}))
        XCTAssertFalse(userLevelsKey.contains(where: { $0.contains(where: { $0.key == "ID" && $0.value == nonUpdatedKey.keyID })}))
        XCTAssertFalse(userLevelsKey.contains(where: { $0.contains(where: { $0.key == "PrivateKey" && $0.value == nonUpdatedKey.privateKey })}))
    }
}
