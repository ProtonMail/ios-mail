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

class DeviceCapacityTests: XCTestCase {
    private typealias SUT = DeviceCapacity

    private let fileManager: FileManager = .default
    private var testDirectory: URL!

    private var testFileURL: URL {
        testDirectory.appendingPathComponent("foo.bin")
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        testDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: testDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try fileManager.removeItem(at: testDirectory)

        testDirectory = nil

        try super.tearDownWithError()
    }

    func testDisk_detectsDecreaseInFreeSpaceAfterWritingAFile() throws {
        let freeSpaceBeforeWrite = SUT.Disk.free()

        let testData = Data("foo".utf8)
        try testData.write(to: testFileURL)

        let freeSpaceAfterWrite = SUT.Disk.free()

        let expectedDecreaseInReportedSpace = 4096 // note: actually not test data size!
        XCTAssertEqual(freeSpaceBeforeWrite - freeSpaceAfterWrite, expectedDecreaseInReportedSpace)
    }
}
