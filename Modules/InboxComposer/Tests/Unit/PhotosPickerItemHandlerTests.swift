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

import CoreTransferable
@testable import InboxComposer
import InboxCoreUI
import InboxTesting
import PhotosUI
import proton_app_uniffi
import SwiftUI
import XCTest

final class PhotosPickerItemHandlerTests: BaseTestCase {
    private var sut: PhotosPickerItemHandler!
    private var testsHelper: PhotosPickerItemHandlerTestsHelper!
    private var mockDraft: MockDraft!
    private var capturedErrors: [DraftAttachmentError]!
    private var mockOnErrors: (([DraftAttachmentError]) -> Void)!

    override func setUpWithError() throws {
        testsHelper = try .init()
        capturedErrors = []
        mockOnErrors = { self.capturedErrors.append(contentsOf: $0) }
        mockDraft = .emptyMock
        mockDraft.mockAttachmentList.attachmentUploadDirectoryURL = testsHelper.destinationFolder
        sut = .init()
    }

    override func tearDownWithError() throws {
        try testsHelper.tearDown()
        capturedErrors = nil
        mockOnErrors = nil
        mockDraft = nil
        sut = nil
    }

    func testAddPickerPhotos_whenNoError_itShouldAddFilesToDraft() async throws {
        let mockItem1 = try testsHelper.makeMockPhotosPickerItem(fileName: "file1.txt", createFile: true)
        let mockItem2 = try testsHelper.makeMockPhotosPickerItem(fileName: "file2.txt", createFile: true)

        await sut.addPickerPhotos(to: mockDraft, photos: [mockItem1, mockItem2], onErrors: mockOnErrors)

        let destFile1 = testsHelper.destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = testsHelper.destinationFolder.appendingPathComponent("file2.txt")

        XCTAssertTrue(capturedErrors.isEmpty)
        XCTAssertEqual(mockDraft.mockAttachmentList.capturedAddCalls.map(\.path), [destFile1.path, destFile2.path])
    }

    func testAddPickerPhotos_whenDraftAddPathReturnsErrorForOneItem_itShouldCallAddFilesToDraftForAllItems_andReturnError() async throws {
        let error = DraftAttachmentError.reason(DraftAttachmentErrorReason.attachmentTooLarge)
        mockDraft.mockAttachmentList.mockAttachmentListAddResult = [("file1.txt", .error(error)), ("file2.txt", .ok)]
        let mockItem1 = try testsHelper.makeMockPhotosPickerItem(fileName: "file1.txt", createFile: true)
        let mockItem2 = try testsHelper.makeMockPhotosPickerItem(fileName: "file2.txt", createFile: true)

        await sut.addPickerPhotos(to: mockDraft, photos: [mockItem1, mockItem2], onErrors: mockOnErrors)

        let destFile1 = testsHelper.destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = testsHelper.destinationFolder.appendingPathComponent("file2.txt")

        XCTAssertEqual(mockDraft.mockAttachmentList.capturedAddCalls.map(\.path), [destFile1.path, destFile2.path])
        XCTAssertEqual(capturedErrors, [error])
    }

    func testAddPickerPhotos_whenNoErrors_itShouldMoveFilesToDestinationFolder() async throws {
        let mockItem1 = try testsHelper.makeMockPhotosPickerItem(fileName: "file1.txt", createFile: true)
        let mockItem2 = try testsHelper.makeMockPhotosPickerItem(fileName: "file2.txt", createFile: true)

        await sut.addPickerPhotos(to: mockDraft, photos: [mockItem1, mockItem2], onErrors: mockOnErrors)

        let destFile1 = testsHelper.destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = testsHelper.destinationFolder.appendingPathComponent("file2.txt")

        XCTAssertTrue(capturedErrors.isEmpty)
        XCTAssertEqual(Set(mockDraft.mockAttachments()), Set([destFile1.path, destFile2.path]))
        XCTAssertTrue(testsHelper.fileExists(at: destFile1.path))
        XCTAssertTrue(testsHelper.fileExists(at: destFile2.path))
    }

    func testAddPickerPhotos_whenSameItemIsAddedTwice_itShouldMoveFilesToDestinationFolderWithUniqueNames() async throws {
        let mockItem1 = try testsHelper.makeMockPhotosPickerItem(fileName: "file1.txt", createFile: true)
        let mockItem2 = try testsHelper.makeMockPhotosPickerItem(fileName: "file1.txt", createFile: true)

        await sut.addPickerPhotos(to: mockDraft, photos: [mockItem1, mockItem2], onErrors: mockOnErrors)

        let destFile1 = testsHelper.destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = testsHelper.destinationFolder.appendingPathComponent("file1-1.txt")

        XCTAssertTrue(capturedErrors.isEmpty)
        XCTAssertEqual(Set(mockDraft.mockAttachments()), Set([destFile1.path, destFile2.path]))
        XCTAssertTrue(testsHelper.fileExists(at: destFile1.path))
        XCTAssertTrue(testsHelper.fileExists(at: destFile2.path))
    }

    func testAddPickerPhotos_whenPhotoItemTypeIsHeic_itShouldCreateAJpegInDestinationFolder() async throws {
        let mockItem1 = try testsHelper.makeMockPhotosPickerHeicImage(fileName: "image1.heic")

        await sut.addPickerPhotos(to: mockDraft, photos: [mockItem1], onErrors: mockOnErrors)

        let destFile1 = testsHelper.destinationFolder.appendingPathComponent("image1.jpg")
        XCTAssertTrue(capturedErrors.isEmpty)
        XCTAssertEqual(Set(mockDraft.mockAttachments()), Set([destFile1.path]))
        XCTAssertTrue(testsHelper.fileExists(at: destFile1.path))
    }

    func testAddPickerPhotos_whenUnexpectedError_itShouldNotMoveFilesToDestinationFolder_andReturnError() async throws {
        let mockItem1 = try testsHelper.makeMockPhotosPickerItem(fileName: "file1.txt", createFile: false)

        await sut.addPickerPhotos(to: mockDraft, photos: [mockItem1], onErrors: mockOnErrors)

        let destFile1 = testsHelper.destinationFolder.appendingPathComponent("file1.txt")
        XCTAssertEqual(mockDraft.mockAttachments(), [])
        XCTAssertFalse(testsHelper.fileExists(at: destFile1.path))
        XCTAssertEqual(capturedErrors, [PhotosPickerItemHandler.unexpectedError])
    }

    func testAddPickerPhotos_whenMultipleUnexpectedError_itShouldReturnSameNumberOfErrors() async throws {
        let mockItem1 = try testsHelper.makeMockPhotosPickerItem(fileName: "file1.txt", createFile: false)
        let mockItem2 = try testsHelper.makeMockPhotosPickerItem(fileName: "file2.txt", createFile: false)

        await sut.addPickerPhotos(to: mockDraft, photos: [mockItem1, mockItem2], onErrors: mockOnErrors)

        XCTAssertEqual(capturedErrors, [PhotosPickerItemHandler.unexpectedError, PhotosPickerItemHandler.unexpectedError])
    }
}

struct MockPhotosPickerItem: PhotosPickerItemTransferable {
    let url: URL

    func loadTransferable<T>(type: T.Type) async throws -> T? where T: Transferable {
        if FileManager.default.fileExists(atPath: url.path) {
            return PhotosItemFile(url: url) as? T
        } else {
            throw NSError(domain: "MockError", code: -1, userInfo: nil)
        }
    }
}

struct PhotosPickerItemHandlerTestsHelper {
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

    func fileExists(at path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    func makeMockPhotosPickerItem(fileName: String, createFile: Bool) throws -> MockPhotosPickerItem {
        /// by adding UUID, we simulate the PhotosItemFile `transferRepresentation` implementation which copies each received file to a separate unique folder
        let receivedFileURL = tempDirectory.appendingPathComponent("\(UUID().uuidString)/\(fileName)")
        try fileManager.createDirectory(at: receivedFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if createFile {
            try "Some content".write(to: receivedFileURL, atomically: true, encoding: .utf8)
        }
        return MockPhotosPickerItem(url: receivedFileURL)
    }

    func makeMockPhotosPickerHeicImage(fileName: String) throws -> MockPhotosPickerItem {
        /// by adding UUID, we simulate the PhotosItemFile `transferRepresentation` implementation which copies each received file to a separate unique folder
        let receivedFileURL = tempDirectory.appendingPathComponent("\(UUID().uuidString)/\(fileName)")
        try fileManager.createDirectory(at: receivedFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let imageData = createMockImageData()
        try imageData.write(to: receivedFileURL)
        return MockPhotosPickerItem(url: receivedFileURL)
    }

    private func createMockImageData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return image.pngData()!
    }
}
