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

import ProtonCoreKeymaker
import SDWebImage
import XCTest

@testable import ProtonMail

class EncryptedCacheTests: XCTestCase {
    private var internalCache: SDDiskCache!
    private var mainKey: MainKey!
    private var sut: EncryptedCache!
    private let cacheFolderName = "EncryptedCacheTests"
    private var testContainer: TestContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()

        testContainer = .init()

        let config = SDImageCacheConfig()
        config.diskCacheWritingOptions = [.atomic, .completeFileProtection]
        config.maxDiskAge = -1
        config.maxDiskSize = 1000
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(cacheFolderName, isDirectory: true)
        internalCache = SDDiskCache(cachePath: cacheDir.path, config: config)

        mainKey = try XCTUnwrap(testContainer.keyMaker.mainKey(by: testContainer.keychain.randomPinProtection))

        sut = EncryptedCache(internalCache: internalCache, dependencies: testContainer)
        sut.purge()
    }

    override func tearDownWithError() throws {
        sut.purge()
        sut = nil
        testContainer = nil
        mainKey = nil

        try super.tearDownWithError()
    }

    func testValuesAreEncrypted() async throws {
        let key = "foo"
        let value = Data("foo".utf8)

        try sut.encryptAndSaveData(value, forKey: key)

        await sleep(milliseconds: 200)

        let storedData = try XCTUnwrap(internalCache.data(forKey: key))

        XCTAssertNotEqual(value, storedData)

        let locked = Locked<Data>(encryptedValue: storedData)
        let plaintext = try locked.unlock(with: mainKey)

        XCTAssertEqual(value, plaintext)
    }

    func testRemove_removesTheValue() async throws {
        let keys = ["foo", "bar"]
        let value = Data("foo".utf8)

        for key in keys {
            try sut.encryptAndSaveData(value, forKey: key)
        }

        sut.purge()

        await sleep(milliseconds: 200)

        for key in keys {
            XCTAssertNil(try sut.decryptedData(forKey: key))
        }
    }

    func testPurge_removesAllValues() async throws {
        let keys = ["foo", "bar"]
        let value = Data("foo".utf8)

        for key in keys {
            try sut.encryptAndSaveData(value, forKey: key)
        }

        sut.removeData(forKey: keys[0])

        await sleep(milliseconds: 200)

        XCTAssertNil(try sut.decryptedData(forKey: keys[0]))
        XCTAssertNotNil(try sut.decryptedData(forKey: keys[1]))
    }
}
