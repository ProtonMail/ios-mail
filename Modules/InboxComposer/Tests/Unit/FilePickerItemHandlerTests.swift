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
import InboxCoreUI
import InboxTesting
import proton_app_uniffi
import XCTest

final class FilePickerItemHandlerTests: BaseTestCase {
    var sut: FilePickerItemHandler!
    private var fileManager: FileManager!
    private var tempDirectory: URL!
    private var destinationFolder: URL!
    private var toastStateStore: ToastStateStore!
    private var mockDraft: MockDraft!

    override func setUpWithError() throws {
        fileManager = .default
        tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        destinationFolder = tempDirectory.appendingPathComponent("destination/")

        toastStateStore = .init(initialState: .initial)
        mockDraft = .emptyMock
        mockDraft.mockAttachmentList.attachmentUploadDirectoryURL = destinationFolder
        sut = .init(toastStateStore: toastStateStore)
    }

    override func tearDownWithError() throws {
        try fileManager.removeItem(at: tempDirectory)
        toastStateStore = nil
        mockDraft = nil
        fileManager = nil
        tempDirectory = nil
        sut = nil
    }

    func testAddSelectedFiles_whenNoError_itShouldAddFilesToDraft() async throws {
        let file1 = try prepareItem(fileName: "file1.txt", createFile: true)
        let file2 = try prepareItem(fileName: "file2.txt", createFile: true)

        await sut.addSelectedFiles(to: mockDraft, selectionResult: .success([file1, file2]))

        let destFile1 = destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = destinationFolder.appendingPathComponent("file2.txt")

        XCTAssertEqual(mockDraft.mockAttachmentList.capturedAttachments, [destFile1.path, destFile2.path])
    }

    func testAddSelectedFiles_whenDraftAddPathReturnsErrorForOneItem_itShouldCallAddFilesToDraftForAllItems() async throws {
        let error = DraftAttachmentError.reason(DraftAttachmentErrorReason.attachmentTooLarge)
        mockDraft.mockAttachmentList.mockAttachmentListAddResult = [("file1.txt", .error(error)), ("file2.txt", .ok)]
        let file1 = try prepareItem(fileName: "file1.txt", createFile: true)
        let file2 = try prepareItem(fileName: "file2.txt", createFile: true)

        await sut.addSelectedFiles(to: mockDraft, selectionResult: .success([file1, file2]))

        let destFile1 = destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = destinationFolder.appendingPathComponent("file2.txt")

        XCTAssertEqual(mockDraft.mockAttachmentList.capturedAttachments, [destFile1.path, destFile2.path])
    }

    func testAddSelectedFiles_whenThereIsAnErrorInTheResults_itShouldShowErrorToast() async throws {
        let error = NSError(domain: "".notLocalized, code: -1,
            userInfo: [NSLocalizedDescriptionKey: "the localised error".notLocalized]
        )
        await sut.addSelectedFiles(to: mockDraft, selectionResult: .failure(error))
        XCTAssertEqual(toastStateStore.state.toasts, [.error(message: error.localizedDescription)])
    }

    func testAddSelectedFiles_whenThereIsNoErrorCopyingFiles_itShouldCopyFilesToDestinationFolder() async throws {
        let file1 = try prepareItem(fileName: "file1.txt", createFile: true)
        let file2 = try prepareItem(fileName: "file2.txt", createFile: true)

        await sut.addSelectedFiles(to: mockDraft, selectionResult: .success([file1, file2]))

        let destFile1 = destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = destinationFolder.appendingPathComponent("file2.txt")

        XCTAssertEqual(Set(mockDraft.mockAttachments()), Set([destFile1.path, destFile2.path]))
        XCTAssertTrue(fileManager.fileExists(atPath: destFile1.path))
        XCTAssertTrue(fileManager.fileExists(atPath: destFile2.path))
    }

    func testAddSelectedFiles_whenSameFileNameAddedTwice_itShouldCopyItTwice() async throws {
        let file1 = try prepareItem(fileName: "file1.txt", createFile: true)
        let file2 = try prepareItem(fileName: "file1.txt", createFile: true)

        await sut.addSelectedFiles(to: mockDraft, selectionResult: .success([file1, file2]))

        let destFile1 = destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = destinationFolder.appendingPathComponent("file1-1.txt")

        XCTAssertEqual(Set(mockDraft.mockAttachments()), Set([destFile1.path, destFile2.path]))
        XCTAssertTrue(fileManager.fileExists(atPath: destFile1.path))
        XCTAssertTrue(fileManager.fileExists(atPath: destFile2.path))
    }

    func testAddSelectedFiles_whenThereIsAnErrorCopyingFiles_itShouldCopyCorrectFilesAndSignalTheErrorInTheResult() async throws {
        let file1 = try prepareItem(fileName: "file1.txt", createFile: false)
        let file2 = try prepareItem(fileName: "file2.txt", createFile: true)

        await sut.addSelectedFiles(to: mockDraft, selectionResult: .success([file1, file2]))

        let destFile1 = destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = destinationFolder.appendingPathComponent("file2.txt")
        XCTAssertEqual(mockDraft.mockAttachments(), [destFile2.path])
        XCTAssertFalse(fileManager.fileExists(atPath: destFile1.path))
        XCTAssertTrue(fileManager.fileExists(atPath: destFile2.path))
    }

    func testAddSelectedFiles_whenThereIsAnErrorCopyingFiles_itShouldShowErrorToast() async throws {
        let file1 = try prepareItem(fileName: "file1.txt", createFile: false)

        await sut.addSelectedFiles(to: mockDraft, selectionResult: .success([file1]))

        XCTAssertEqual(toastStateStore.state.toasts, [.error(message: L10n.Attachments.attachmentCouldNotBeAdded.string)])
    }

    private func prepareItem(fileName: String, createFile: Bool) throws -> URL {
        let newFile = tempDirectory.appendingPathComponent(fileName)
        try fileManager.createDirectory(at: newFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        if createFile {
            try "Some content".write(to: newFile, atomically: true, encoding: .utf8)
        }
        return newFile
    }
}
