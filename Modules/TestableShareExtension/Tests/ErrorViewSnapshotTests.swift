//
// Copyright (c) 2025 Proton Technologies AG
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

import Foundation
import InboxSnapshotTesting
import Testing

@testable import TestableShareExtension

@MainActor
struct ErrorViewSnapshotTests {
    @Test
    func errorViewWithButtonToOpenApp() {
        let sut = ErrorView(error: MailUserSessionFactoryError.notSignedIn, dismissExtension: {}, launchMainApp: {})
        assertSnapshotsOnIPhoneX(of: sut)
    }

    @Test
    func errorViewWithoutButtonToOpenApp() {
        let sut = ErrorView(error: TestError(), dismissExtension: {}, launchMainApp: {})
        assertSnapshotsOnIPhoneX(of: sut)
    }
}

private struct TestError: LocalizedError {
    let errorDescription: String? = "Something failed."
}
