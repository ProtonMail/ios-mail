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

@testable import ProtonMail
import InboxSnapshotTesting
import SnapshotTesting
import SwiftUI
import Testing

@MainActor
struct OnboardingScreenSnapshotTests {
    @Test(arguments: [0, 1, 2])
    func testInitialStateLayoutsCorrectly(selectedPageIndex: Int) {
        let allPhones: [(String, ViewImageConfig)] = .allPhones

        allPhones.forEach { name, config in
            assertSnapshots(
                matching: makeSUT(selectedPageIndex: selectedPageIndex),
                on: [(name, config)],
                named: "page_\(selectedPageIndex)"
            )
        }
    }

    // MARK: - Private

    private func makeSUT(selectedPageIndex: Int) -> UIHostingController<some View> {
        let sut = OnboardingScreen(selectedPageIndex: selectedPageIndex)
        return UIHostingController(rootView: sut)
    }
}
