// Copyright (c) 2023 Proton Technologies AG
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

@testable import ProtonMail
import XCTest

final class SenderImageRequestTests: XCTestCase {
    let email = "\(String.randomString(10))@pm.me"
    let uid = String.randomString(10)
    let isDarkMode = Bool.random()
    let bimiSelector = String.randomString(20)

    func testInit_withAddressAndUID() {
        let sut = SenderImageRequest(email: email, uid: uid, isDarkMode: isDarkMode)

        let value = isDarkMode ? "dark" : "light"
        XCTAssertEqual(
            sut.path,
            "/core/v4/images/logo?Address=\(email)&Mode=\(value)&UID=\(uid)"
        )
    }

    func testInit_withAllParameters() {
        let sut = SenderImageRequest(
            email: email,
            uid: uid,
            isDarkMode: isDarkMode,
            size: .small,
            bimiSelector: bimiSelector
        )

        let value = isDarkMode ? "dark" : "light"
        XCTAssertEqual(
            sut.path,
            "/core/v4/images/logo?Address=\(email)&Mode=\(value)&Size=\(32)&BimiSelector=\(bimiSelector)&UID=\(uid)"
        )
    }
}
