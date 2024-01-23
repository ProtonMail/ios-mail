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

import XCTest
import ProtonCoreKeymaker
@testable import ProtonMail

final class UserObjectsPersistenceTests: XCTestCase {
    private let directory = URL.cachesDirectory
    private var customKeychain: Keychain!
    private var keymaker: Keymaker!
    var sut: UserObjectsPersistence!

    override func setUp() {
        super.setUp()
        sut = UserObjectsPersistence(directoryURL: directory)
        customKeychain = .init(service: String.randomString(10),
                               accessGroup: "2SB5Z68H26.ch.protonmail.protonmail")
        keymaker = Keymaker(autolocker: nil, keychain: customKeychain)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testWriteShouldWriteToThePathComponent() throws {
        /// Given data set with main key
        let testData = TestData(int: Int.random(in: 0...100), bool: Bool.random())
        let mainKey = keymaker.mainKey(by: customKeychain.randomPinProtection)!

        /// When encrypting and writing to disk
        try sut.write(testData, key: mainKey)
        let expectedURL = directory.appendingPathComponent( TestData.pathComponent)

        /// Then a file should exist at the expect URL
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedURL.relativePath))
    }

    func testWriteShouldNotWriteDataInClear() throws {
        /// Given data set with main key
        let testData = TestData(int: Int.random(in: 0...100), bool: Bool.random())
        let mainKey = keymaker.mainKey(by: customKeychain.randomPinProtection)!

        /// When writing to disk
        try sut.write(testData, key: mainKey)

        
        let expectedURL = directory.appendingPathComponent( TestData.pathComponent)
        let writtenData = try Data(contentsOf: expectedURL)
        let jsonEncodedData = try JSONEncoder().encode(testData)

        /// Then written data should be different from the clear data representation
        XCTAssertNotEqual(writtenData, jsonEncodedData)
    }

    func testWriteShouldWriteDataEncryptedWithMainKey() throws {
        /// Given data set with main key
        let testData = TestData(int: Int.random(in: 0...100), bool: Bool.random())
        let mainKey = keymaker.mainKey(by: customKeychain.randomPinProtection)!

        /// When writing to disk
        try sut.write(testData, key: mainKey)
        let expectedURL = directory.appendingPathComponent( TestData.pathComponent)

        let writtenData = try Data(contentsOf: expectedURL)
        let decryptedData = try Locked<Data>(encryptedValue: writtenData).unlock(with: mainKey)
        let decodedData = try JSONDecoder().decode(TestData.self, from: decryptedData)

        /// Then data decrypted should be equal to original data set
        XCTAssertEqual(testData, decodedData)
    }

    func testReadShouldDecryptAndDecodeData() throws {
        /// Given data set encoded and written encrypted to the expected URL
        let testData = TestData(int: Int.random(in: 0...100), bool: Bool.random())
        let mainKey = keymaker.mainKey(by: customKeychain.randomPinProtection)!
        let encodedData = try JSONEncoder().encode(testData)
        let encryptedData = try Locked<Data>(clearValue: encodedData, with: mainKey)
        let expectedURL = directory.appendingPathComponent(TestData.pathComponent)
        try encryptedData.encryptedValue.write(to: expectedURL)

        /// When reading
        let readObject = try sut.read(TestData.self, key: mainKey)

        /// Then return object should be equal to original object
        XCTAssertEqual(readObject, testData)
    }    
}

struct TestData: Equatable & Codable & FilePersistable {
    let int: Int
    let bool: Bool
    static var pathComponent: String {
        "testData.data"
    }
}

extension Locked where T == TestData {
    init(clearValue: T, with key: MainKey) throws {
        let data = try JSONEncoder().encode(clearValue)
        let locked = try Locked<Data>(clearValue: data, with: key)
        self.init(encryptedValue: locked.encryptedValue)
    }

}
