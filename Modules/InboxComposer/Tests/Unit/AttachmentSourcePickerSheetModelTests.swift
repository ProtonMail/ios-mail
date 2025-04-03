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
import Testing

final class AttachmentSourcePickerSheetModelTests {
    var sut: AttachmentSourcePickerSheetModel!

    @Test
    func testIsAuthorized_whenCameraIsPassed_andItIsAuthorized_itReutrnsTrue() {
        sut = .init(cameraPermissionProvider: .testAuthorized)

        #expect(sut.isAuthorized(source: .camera) == true)
    }

    @Test
    func testIsAuthorized_whenCameraIsPassed_andItIsDenied_itReutrnsFalse() {
        sut = .init(cameraPermissionProvider: .testDenied)

        #expect(sut.isAuthorized(source: .camera) == false)
    }
}

private extension CameraPermissionProvider {

    static var testAuthorized: Self {
        .init { _ in .authorized }
    }

    static var testDenied: Self {
        .init { _ in .denied }
    }
}
