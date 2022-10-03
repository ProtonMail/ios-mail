// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

@testable import ProtonMail
import XCTest

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
