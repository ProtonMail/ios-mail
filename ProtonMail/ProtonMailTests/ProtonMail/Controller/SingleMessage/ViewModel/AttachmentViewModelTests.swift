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

class AttachmentViewModelTests: XCTestCase {

    var sut: AttachmentViewModel!
    var testAttachments: [AttachmentInfo] = []

    override func tearDown() {
        super.tearDown()
        testAttachments.removeAll()
    }

    func testInit_withNonInlineAttachments_realAttachmentIsFalse_addAllAttachments() {
        for _ in 0..<10 {
            testAttachments.append(makeAttachment(isInline: false))
        }

        sut = AttachmentViewModel()
        sut.attachmentHasChanged(attachments: testAttachments, mimeAttachments: [])

        XCTAssertEqual(sut.attachments.count, testAttachments.count)
        XCTAssertEqual(sut.numberOfAttachments, testAttachments.count)
    }

    func testGetTotalSizeOfAllAttachments() {
        for _ in 0..<10 {
            testAttachments.append(makeAttachment(isInline: true))
        }

        sut = AttachmentViewModel()
        sut.attachmentHasChanged(attachments: testAttachments, mimeAttachments: [])

        let expected = testAttachments.reduce(into: 0, { $0 = $0 + $1.size })
        XCTAssertEqual(sut.totalSizeOfAllAttachments, expected)
    }

    func testAddMimeAttachment() {
        let attachment = MimeAttachment(filename: String.randomString(10), size: 10, mime: "", path: nil, disposition: nil)
        let expectation1 = expectation(description: "closure is called")

        sut = AttachmentViewModel()
        sut.reloadView = {
            expectation1.fulfill()
        }

        sut.attachmentHasChanged(attachments: [], mimeAttachments: [attachment])
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(sut.numberOfAttachments, 1)
    }

    func testAddMimeAttachment_AddDuplicateItem() {
        let attachment = MimeAttachment(filename: String.randomString(10), size: 10, mime: "", path: nil, disposition: nil)
        let expectation1 = expectation(description: "closure is called")

        sut = AttachmentViewModel()
        sut.reloadView = {
            expectation1.fulfill()
        }

        sut.attachmentHasChanged(attachments: [], mimeAttachments: [attachment, attachment])
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(sut.numberOfAttachments, 1)
    }

    private func makeAttachment(isInline: Bool) -> AttachmentInfo {
        return AttachmentInfo(
            fileName: String.randomString(50),
            size: 99,
            mimeType: "txt",
            localUrl: nil,
            isDownloaded: true,
            id: "",
            isInline: isInline,
            objectID: nil,
            contentID: nil,
            order: -1
        )
    }
}
