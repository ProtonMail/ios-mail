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

import XCTest

@testable import ProtonMail

class SecureTemporaryFileTests: XCTestCase {
    private let fileManager = FileManager.default

    private var testData: Data {
        Data("foo".utf8)
    }

    private var testFileName: String {
        "example.file"
    }

    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: fileManager.temporaryDirectory)

        try super.tearDownWithError()
    }

    func testCreatesFileWithContentsWhenInitialized() throws {
        let sut = SecureTemporaryFile(data: testData, name: testFileName)

        let savedData = try Data(contentsOf: sut.url)
        XCTAssertEqual(savedData, testData)
    }

    func testDeletesTemporaryFileWhenDeinitialized() throws {
        var sut: SecureTemporaryFile? = SecureTemporaryFile(data: testData, name: testFileName)
        let url = try XCTUnwrap(sut).url

        sut = nil

        XCTAssertThrowsError(try Data(contentsOf: url))
    }

    func testDeletesTemporaryFileOnDemand() throws {
        let sut = SecureTemporaryFile(data: testData, name: testFileName)

        SecureTemporaryFile.cleanUpResidualFiles()

        XCTAssertThrowsError(try Data(contentsOf: sut.url))
    }

    func testDoesNotAssertOnFileNotFoundErrorIfFilesAreCleanedUpEarlier() throws {
        var sut: SecureTemporaryFile? = SecureTemporaryFile(data: testData, name: testFileName)
        _ = sut

        SecureTemporaryFile.cleanUpResidualFiles()
        sut = nil

        XCTAssert(true)
    }

    func testHandlesURLsInFileNames() throws {
        let problematicNames: [(String, String)] = [
            (
                "😀",
                "😀"
            ),
            (
                "EPT - Your Test Email - https://www.emailprivacytester.com/test?code=63075af3a959590022d717ae.pdf",
                "EPT - Your Test Email - https:%2F%2Fwww.emailprivacytester.com%2Ftest?code=63075af3a959590022d717ae.pdf"
            )
        ]

        for (receivedName, expectedName) in problematicNames {
            let sut = SecureTemporaryFile(data: testData, name: receivedName)
            XCTAssertEqual(sut.url.lastPathComponent, expectedName)
        }
    }
}
