// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import PromiseKit
@testable import ProtonMail
import XCTest

final class AttachmentConvertibleStub: AttachmentConvertible {
    var dataSize: Int
    init() { dataSize = 0 }
    func toAttachment(_ message: Message, fileName: String, type: String, stripMetadata: Bool, isInline: Bool) -> Promise<Attachment?> {
        fatalError()
    }
}

final class MIMETypeTests: XCTestCase {
    var sut: AttachmentConvertibleStub!

    override func setUp() {
        super.setUp()
        sut = AttachmentConvertibleStub()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testContainsExifShouldReturnTrueForImageTypes() {
        XCTAssertTrue(sut.containsExifMetadata(mimeType: "image/jpg"))
        XCTAssertTrue(sut.containsExifMetadata(mimeType: "IMAGE/PNG"))
        XCTAssertTrue(sut.containsExifMetadata(mimeType: "image/tiff"))
    }

    func testContainsExifShouldReturnTrueForVideoTypes() {
        XCTAssertTrue(sut.containsExifMetadata(mimeType: "video/mov"))
        XCTAssertTrue(sut.containsExifMetadata(mimeType: "VIDEO/MP4"))
        XCTAssertTrue(sut.containsExifMetadata(mimeType: "video/m4v"))
    }

    func testContainsExifShouldReturnFalseForPDFTypes() {
        XCTAssertFalse(sut.containsExifMetadata(mimeType: "application/pdf"))
        XCTAssertFalse(sut.containsExifMetadata(mimeType: "APPLICATION/PDF"))
    }
}
