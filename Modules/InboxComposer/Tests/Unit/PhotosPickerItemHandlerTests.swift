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
import SwiftUI
import InboxTesting
import XCTest

final class PhotosPickerItemHandlerTests: BaseTestCase {
    private var sut: PhotosPickerItemHandler!
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
        sut = nil
    }

    func testAddPickerPhotos_whenLoadTransferableDoesNotReturnError_itShouldMoveFilesToDestinationFolder() async throws {
        let mockItem1 = try makeMockPhotosPickerItem(fileName: "file1.txt", createFile: true)
        let mockItem2 = try makeMockPhotosPickerItem(fileName: "file2.txt", createFile: true)

        await sut.addPickerPhotos(to: mockDraft, photos: [mockItem1, mockItem2])

        let destFile1 = destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = destinationFolder.appendingPathComponent("file2.txt")

        XCTAssertEqual(Set(mockDraft.mockAttachments()), Set([destFile1.path, destFile2.path]))
        XCTAssertTrue(fileManager.fileExists(atPath: destFile1.path))
        XCTAssertTrue(fileManager.fileExists(atPath: destFile2.path))
    }

    func testAddPickerPhotos_whenSameItemIsAddedTwice_itShouldMoveFilesToDestinationFolderWithUniqueNames() async throws {
        let mockItem1 = try makeMockPhotosPickerItem(fileName: "file1.txt", createFile: true)
        let mockItem2 = try makeMockPhotosPickerItem(fileName: "file1.txt", createFile: true)

        await sut.addPickerPhotos(to: mockDraft, photos: [mockItem1, mockItem2])

        let destFile1 = destinationFolder.appendingPathComponent("file1.txt")
        let destFile2 = destinationFolder.appendingPathComponent("file1-1.txt")

        XCTAssertEqual(Set(mockDraft.mockAttachments()), Set([destFile1.path, destFile2.path]))
        XCTAssertTrue(fileManager.fileExists(atPath: destFile1.path))
        XCTAssertTrue(fileManager.fileExists(atPath: destFile2.path))
    }


    func testAddPickerPhotos_whenPhotoItemTypeIsHeic_itShouldCreateAJpegInDestinationFolder() async throws {
        let mockItem1 = try makeMockPhotosPickerHeicImage(fileName: "image1.heic")

        await sut.addPickerPhotos(to: mockDraft, photos: [mockItem1])

        let destFile1 = destinationFolder.appendingPathComponent("image1.jpg")
        XCTAssertEqual(Set(mockDraft.mockAttachments()), Set([destFile1.path]))
        XCTAssertTrue(fileManager.fileExists(atPath: destFile1.path))
    }

    func testAddPickerPhotos_whenLoadTransferableReturnsError_itShouldNotMoveFilesToDestinationFolder() async throws {
        let mockItem1 = try makeMockPhotosPickerItem(fileName: "file1.txt", createFile: false)

        await sut.addPickerPhotos(to: mockDraft, photos: [mockItem1])

        let destFile1 = destinationFolder.appendingPathComponent("file1.txt")
        XCTAssertEqual(mockDraft.mockAttachments(), [])
        XCTAssertFalse(fileManager.fileExists(atPath: destFile1.path))
    }

    func testAddPickerPhotos_whenLoadTransferableReturnsError_itShouldShowErrorToast() async throws {
        let mockItem1 = try makeMockPhotosPickerItem(fileName: "file1.txt", createFile: false)

        await sut.addPickerPhotos(to: mockDraft, photos: [mockItem1])

        XCTAssertEqual(toastStateStore.state.toasts, [.error(message: L10n.Attachments.attachmentCouldNotBeAdded.string)])
    }

    private func makeMockPhotosPickerItem(fileName: String, createFile: Bool) throws -> MockPhotosPickerItem {
        /// by adding UUID, we simulate the PhotosItemFile `transferRepresentation` implementation which copies each received file to a separate unique folder
        let receivedFileURL = tempDirectory.appendingPathComponent("\(UUID().uuidString)/\(fileName)")
        try fileManager.createDirectory(at: receivedFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if createFile {
            try "Some content".write(to: receivedFileURL, atomically: true, encoding: .utf8)
        }
        return MockPhotosPickerItem(url: receivedFileURL)
    }

    private func makeMockPhotosPickerHeicImage(fileName: String) throws -> MockPhotosPickerItem {
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
