// Copyright (c) 2024 Proton Technologies AG
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

@testable import InboxComposer

final class FileManagerAttachmentHelpersTests: XCTestCase {
    let sut = FileManager.default
    var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = sut.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try sut.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try sut.removeItem(at: tempDirectory)
    }

    // MARK: copyToUniqueURL

    func testCopyToUniqueURL_whenFileExists_itShouldCopyTheFile() throws {
        let sourceFile = tempDirectory.appendingPathComponent("testFile.txt")
        let destinationFolder = tempDirectory.appendingPathComponent("destination")
        try "Test content".write(to: sourceFile, atomically: true, encoding: .utf8)

        let copiedFile = try sut.copyToUniqueURL(file: sourceFile, to: destinationFolder)

        XCTAssertTrue(sut.fileExists(atPath: copiedFile.path))
        XCTAssertTrue(sut.fileExists(atPath: sourceFile.path))
    }

    func testCopyToUniqueURL_whenFileDoesNotExist_itShouldThrowError() {
        let nonExistentFile = tempDirectory.appendingPathComponent("nonExistent.txt")
        let destinationFolder = tempDirectory.appendingPathComponent("destination")

        XCTAssertThrowsError(try sut.copyToUniqueURL(file: nonExistentFile, to: destinationFolder))
    }

    // MARK: deleteContainingFolder

    func testDeleteContainingFolder_whenFolderExists_itShouldDeleteTheFolder() throws {
        let fileURL = tempDirectory.appendingPathComponent("folderToDelete/file.txt")
        try sut.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "Some content".write(to: fileURL, atomically: true, encoding: .utf8)

        try sut.deleteContainingFolder(for: fileURL)

        XCTAssertFalse(sut.fileExists(atPath: fileURL.deletingLastPathComponent().path))
    }

    func testDeleteContainingFolder_whenFolderDoesNotExist_itShouldDoNothing() throws {
        let fileURL = tempDirectory.appendingPathComponent("nonExistentFolder/file.txt")

        XCTAssertNoThrow(try sut.deleteContainingFolder(for: fileURL))
    }

    // MARK: moveToUniqueURL

    func testMoveToUniqueURL_whenFileExists_itShouldMoveTheFile() throws {
        let sourceFile = tempDirectory.appendingPathComponent("testFile.txt")
        let destinationFolder = tempDirectory.appendingPathComponent("destination")
        try "Test content".write(to: sourceFile, atomically: true, encoding: .utf8)

        let movedFile = try sut.moveToUniqueURL(file: sourceFile, to: destinationFolder)

        XCTAssertTrue(sut.fileExists(atPath: movedFile.path))
        XCTAssertFalse(sut.fileExists(atPath: sourceFile.path))
    }

    func testMoveToUniqueURL_whenFileDoesNotExist_itShouldThrowError() {
        let nonExistentFile = tempDirectory.appendingPathComponent("nonExistent.txt")
        let destinationFolder = tempDirectory.appendingPathComponent("destination")

        XCTAssertThrowsError(try sut.moveToUniqueURL(file: nonExistentFile, to: destinationFolder))
    }

    // MARK: uniqueFileNameURL

    func testUniqueFileNameURL_whenFileDoesNotExist_itShouldReturnTheOriginalFileNameInTheURL() {
        let folder = tempDirectory!
        let expectedURL = folder.appendingPathComponent("newFile.txt")

        let uniqueURL = sut.uniqueFileNameURL(in: folder, baseName: "newFile", fileExtension: "txt")

        XCTAssertEqual(uniqueURL, expectedURL)
    }

    func testUniqueFileNameURL_whenFileExists_itShouldReturnAnIncrementedFileNameInTheURL() throws {
        let folder = tempDirectory!
        let existingFile = folder.appendingPathComponent("existingFile.txt")
        try "Existing content".write(to: existingFile, atomically: true, encoding: .utf8)

        let uniqueURL = sut.uniqueFileNameURL(in: folder, baseName: "existingFile", fileExtension: "txt")

        XCTAssertEqual(uniqueURL.lastPathComponent, "existingFile-1.txt")
        XCTAssertTrue(uniqueURL.pathExtension == "txt")
    }
}
