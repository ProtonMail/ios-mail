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

import XCTest

@testable import ProtonMail

class FileManager_ExtensionTests: XCTestCase {
    private var sut: FileManager!
    private var testData: Data!
    private var testDirectory: URL!

    private var testFileName: String {
        "foo.bin"
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        sut = .default
        testData = Data("foo".utf8)
        testDirectory = sut.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try sut.createDirectory(at: testDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try sut.removeItem(at: testDirectory)
        sut = nil
        testData = nil
        testDirectory = nil

        try super.tearDownWithError()
    }
}
