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

@testable import InboxComposer
import proton_app_uniffi
import XCTest

final class FilePickerItemHandlerTests: XCTestCase {
    var sut: FilePickerItemHandler!
    private var testsHelper: FilePickerItemHandlerTestsHelper!
    private var mockDraft: MockDraft!
    private var capturedErrors: [DraftAttachmentUploadError]!
    private var mockOnErrors: (([DraftAttachmentUploadError]) -> Void)!

    override func setUpWithError() throws {
        testsHelper = try .init()
        capturedErrors = []
        mockOnErrors = { self.capturedErrors.append(contentsOf: $0) }
        mockDraft = .emptyMock
        mockDraft.mockAttachmentList.attachmentUploadDirectoryURL = testsHelper.destinationFolder
        sut = .init()
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try testsHelper.tearDown()
        capturedErrors = nil
        mockDraft = nil
        sut = nil
        try super.tearDownWithError()
    }

    func testAddSelectedFiles_whenNoError_itShouldAddFilesToDraft() async throws {
        let file1 = try testsHelper.prepareItem(fileName: "file1.txt", createFile: true)
        let file2 = try testsHelper.prepareItem(fileName: "file2.txt", createFile: true)

        await sut.addSelectedFiles(to: mockDraft, selectionResult: .success([file1, file2]), onErrors: mockOnErrors)

        let destFile1 = testsHelper.destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = testsHelper.destinationFolder.appendingPathComponent("file2.txt")

        XCTAssertTrue(capturedErrors.isEmpty)
        XCTAssertEqual(Set(mockDraft.mockAttachmentList.capturedAddCalls.map(\.path)), Set([destFile1.path, destFile2.path]))
    }

    func testAddSelectedFiles_whenDraftAddPathReturnsErrorForOneItem_itShouldCallAddFilesToDraftForAllItems_andReturnError() async throws {
        let error = DraftAttachmentUploadError.reason(DraftAttachmentUploadErrorReason.attachmentTooLarge)
        mockDraft.mockAttachmentList.mockAttachmentListAddResult = [("file1.txt", .error(error)), ("file2.txt", .ok)]
        let file1 = try testsHelper.prepareItem(fileName: "file1.txt", createFile: true)
        let file2 = try testsHelper.prepareItem(fileName: "file2.txt", createFile: true)

        await sut.addSelectedFiles(to: mockDraft, selectionResult: .success([file1, file2]), onErrors: mockOnErrors)

        let destFile1 = testsHelper.destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = testsHelper.destinationFolder.appendingPathComponent("file2.txt")

        XCTAssertEqual(Set(mockDraft.mockAttachmentList.capturedAddCalls.map(\.path)), Set([destFile1.path, destFile2.path]))
        XCTAssertEqual(capturedErrors, [error])
    }

    func testAddSelectedFiles_whenThereIsAnErrorInTheResults_itShouldReturnError() async throws {
        let error = NSError(domain: "".notLocalized, code: -1,
            userInfo: [NSLocalizedDescriptionKey: "the localised error".notLocalized]
        )
        await sut.addSelectedFiles(to: mockDraft, selectionResult: .failure(error), onErrors: mockOnErrors)
        XCTAssertEqual(capturedErrors, [FilePickerItemHandler.unexpectedError])
    }

    func testAddSelectedFiles_whenThereIsNoErrorCopyingFiles_itShouldCopyFilesToDestinationFolder() async throws {
        let file1 = try testsHelper.prepareItem(fileName: "file1.txt", createFile: true)
        let file2 = try testsHelper.prepareItem(fileName: "file2.txt", createFile: true)

        await sut.addSelectedFiles(to: mockDraft, selectionResult: .success([file1, file2]), onErrors: mockOnErrors)

        let destFile1 = testsHelper.destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = testsHelper.destinationFolder.appendingPathComponent("file2.txt")

        XCTAssertTrue(capturedErrors.isEmpty)
        XCTAssertEqual(Set(mockDraft.attachmentPathsFor(dispositon: .attachment)), Set([destFile1.path, destFile2.path]))
        XCTAssertTrue(testsHelper.fileManager.fileExists(atPath: destFile1.path))
        XCTAssertTrue(testsHelper.fileManager.fileExists(atPath: destFile2.path))
    }

    func testAddSelectedFiles_whenSameFileNameAddedTwice_itShouldCopyItTwice() async throws {
        let file1 = try testsHelper.prepareItem(fileName: "file1.txt", createFile: true)
        let file2 = try testsHelper.prepareItem(fileName: "file1.txt", createFile: true)

        await sut.addSelectedFiles(to: mockDraft, selectionResult: .success([file1, file2]), onErrors: mockOnErrors)

        let destFile1 = testsHelper.destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = testsHelper.destinationFolder.appendingPathComponent("file1-1.txt")

        XCTAssertEqual(Set(mockDraft.attachmentPathsFor(dispositon: .attachment)), Set([destFile1.path, destFile2.path]))
        XCTAssertTrue(testsHelper.fileManager.fileExists(atPath: destFile1.path))
        XCTAssertTrue(testsHelper.fileManager.fileExists(atPath: destFile2.path))
        XCTAssertTrue(capturedErrors.isEmpty)
    }

    func testAddSelectedFiles_whenThereIsAnErrorCopyingFiles_itShouldCopyCorrectFiles() async throws {
        let file1 = try testsHelper.prepareItem(fileName: "file1.txt", createFile: false)
        let file2 = try testsHelper.prepareItem(fileName: "file2.txt", createFile: true)

        await sut.addSelectedFiles(to: mockDraft, selectionResult: .success([file1, file2]), onErrors: mockOnErrors)

        let destFile1 = testsHelper.destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = testsHelper.destinationFolder.appendingPathComponent("file2.txt")
        XCTAssertEqual(mockDraft.attachmentPathsFor(dispositon: .attachment), [destFile2.path])
        XCTAssertFalse(testsHelper.fileManager.fileExists(atPath: destFile1.path))
        XCTAssertTrue(testsHelper.fileManager.fileExists(atPath: destFile2.path))
    }

    func testAddSelectedFiles_whenThereIsAnErrorCopyingFiles_itShouldReturnTheErrors() async throws {
        let file1 = try testsHelper.prepareItem(fileName: "file1.txt", createFile: false)
        let file2 = try testsHelper.prepareItem(fileName: "file2.txt", createFile: false)

        await sut.addSelectedFiles(to: mockDraft, selectionResult: .success([file1, file2]), onErrors: mockOnErrors)
        XCTAssertEqual(capturedErrors, [FilePickerItemHandler.unexpectedError, FilePickerItemHandler.unexpectedError])
    }
}

struct FilePickerItemHandlerTestsHelper {
    let fileManager: FileManager = .default
    let tempDirectory: URL
    let destinationFolder: URL
    let destinationFolderPath = "destination/"

    init() throws {
        self.tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        self.destinationFolder = tempDirectory.appendingPathComponent(destinationFolderPath)
        try fileManager.removeItem(at: tempDirectory)
    }

    func tearDown() throws {
        try? fileManager.removeItem(at: tempDirectory)
    }

    func prepareItem(fileName: String, createFile: Bool) throws -> URL {
        let newFile = tempDirectory.appendingPathComponent(fileName)
        try fileManager.createDirectory(at: newFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        if createFile {
            try "Some content".write(to: newFile, atomically: true, encoding: .utf8)
        }
        return newFile
    }
}
