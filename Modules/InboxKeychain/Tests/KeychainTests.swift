//
//  KeymakerTests.swift
//  ProtonCore-Keymaker-Tests - Created on 4/05/2022.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import XCTest

@testable import InboxKeychain

// Tests imported and adapted from https://gitlab.protontech.ch/apple/shared/protoncore/-/blob/a4d22426ef8e737833357fcb4ecd3e82e2144bc6/libraries/Keymaker/Tests/KeychainTests.swift

final class KeychainTests: XCTestCase {
    private var provider: SecItemMethodsProviderMock!
    private var out: Keychain!

    // MARK: - Read

    func testKeychainPassesDataIfFound() throws {
        let data: NSData = Data(repeating: 1, count: 100) as NSData
        setUpSUT(dataToReturn: data, resultCopyMatching: noErr)

        // when
        let result = try XCTUnwrap(try out.dataOrError(forKey: "any.key"))

        // then
        XCTAssertEqual(result, data as Data)
    }

    func testKeychainPassesNilIfNotFound() throws {
        // given
        setUpSUT(resultCopyMatching: errSecItemNotFound)

        // when
        let result = try out.dataOrError(forKey: "any.key")

        // then
        XCTAssertNil(result)
    }

    func testKeychainPassesDataReadError() {
        // given
        setUpSUT(resultCopyMatching: errSecInteractionNotAllowed)

        // when
        XCTAssertThrowsError(try out.dataOrError(forKey: "any.key")) { error in
            // then
            guard case let Keychain.AccessError.readFailed(key, errorCode) = error else { XCTFail(); return }
            XCTAssertEqual(key, "any.key")
            XCTAssertEqual(errorCode, errSecInteractionNotAllowed)
        }
    }

    func testKeychainPassesStringReadError() {
        // given
        setUpSUT(resultCopyMatching: errSecInteractionNotAllowed)

        // when
        XCTAssertThrowsError(try out.stringOrError(forKey: "any.key")) { error in
            // then
            guard case let Keychain.AccessError.readFailed(key, errorCode) = error else { XCTFail(); return }
            XCTAssertEqual(key, "any.key")
            XCTAssertEqual(errorCode, errSecInteractionNotAllowed)
        }
    }

    // MARK: - Write

    func testKeychainReturnsWhenAddingSucceeds() throws {
        // given
        setUpSUT(resultCopyMatching: errSecItemNotFound)

        // when
        try out.setOrError(Data(), forKey: "any.key")
    }

    func testKeychainPassesDataWriteErrorWhenAddingFails() {
        // given
        setUpSUT(resultCopyMatching: errSecItemNotFound, resultAdd: errSecInteractionNotAllowed)

        // when
        XCTAssertThrowsError(try out.setOrError(Data(), forKey: "any.key")) { error in
            // then
            guard case let Keychain.AccessError.writeFailed(key, errorCode) = error else { XCTFail(); return }
            XCTAssertEqual(key, "any.key")
            XCTAssertEqual(errorCode, errSecInteractionNotAllowed)
        }
    }

    func testKeychainPassesStringWriteErrorWhenAddingFails() {
        // given
        setUpSUT(resultCopyMatching: errSecItemNotFound, resultAdd: errSecInteractionNotAllowed)

        // when
        XCTAssertThrowsError(try out.setOrError(String(), forKey: "any.key")) { error in
            // then
            guard case let Keychain.AccessError.writeFailed(key, errorCode) = error else { XCTFail(); return }
            XCTAssertEqual(key, "any.key")
            XCTAssertEqual(errorCode, errSecInteractionNotAllowed)
        }
    }

    // MARK: - Update

    func testKeychainReturnsWhenUpdatingSucceeds() throws {
        // given
        setUpSUT()

        // when
        try out.setOrError(Data(), forKey: "any.key")
    }

    func testKeychainPassesDataWriteErrorWhenUpdatingFails() {
        // given
        setUpSUT(resultUpdate: errSecInteractionNotAllowed)

        // when
        XCTAssertThrowsError(try out.setOrError(Data(), forKey: "any.key")) { error in
            // then
            guard case let Keychain.AccessError.updateFailed(key, errorCode) = error else { XCTFail(); return }
            XCTAssertEqual(key, "any.key")
            XCTAssertEqual(errorCode, errSecInteractionNotAllowed)
        }
    }

    func testKeychainPassesStringWriteErrorWhenUpdatingFails() {
        // given
        setUpSUT(resultUpdate: errSecInteractionNotAllowed)

        // when
        XCTAssertThrowsError(try out.setOrError(String(), forKey: "any.key")) { error in
            // then
            guard case let Keychain.AccessError.updateFailed(key, errorCode) = error else { XCTFail(); return }
            XCTAssertEqual(key, "any.key")
            XCTAssertEqual(errorCode, errSecInteractionNotAllowed)
        }
    }

    // MARK: - Delete

    func testKeychainReturnsIfDeletingSucceeds() throws {
        // given
        setUpSUT()

        // when
        try out.removeOrError(forKey: "any.key")
    }

    func testKeychainPassesRemoveError() {
        // given
        setUpSUT(resultDelete: errSecInteractionNotAllowed)

        // when
        XCTAssertThrowsError(try out.removeOrError(forKey: "any.key")) { error in
            // then
            guard case let Keychain.AccessError.deleteFailed(key, errorCode) = error else { XCTFail(); return }
            XCTAssertEqual(key, "any.key")
            XCTAssertEqual(errorCode, errSecInteractionNotAllowed)
        }
    }
}

extension KeychainTests {
    private func setUpSUT(
        dataToReturn: NSData = .init(),
        resultCopyMatching: OSStatus = noErr,
        resultAdd: OSStatus = noErr,
        resultUpdate: OSStatus = noErr,
        resultDelete: OSStatus = noErr
    ) {
        provider = SecItemMethodsProviderMock(
            dataToReturn: dataToReturn,
            resultCopyMatching: resultCopyMatching,
            resultAdd: resultAdd,
            resultUpdate: resultUpdate,
            resultDelete: resultDelete
        )
        out = Keychain(service: "test.service", accessGroup: "test.access.group", secItemMethodsProvider: provider)
    }
}
