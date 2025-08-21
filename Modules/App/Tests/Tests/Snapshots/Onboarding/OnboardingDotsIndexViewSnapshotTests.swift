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
import InboxTesting
import Testing

@MainActor
final class OnboardingDotsIndexViewSnapshotTests {

    @Test
    func testOnboardingDotsIndexView_With5PagesAnd5thSelected_LayoutsCorrectly() {
        let sut = OnboardingDotsIndexView(pagesCount: 5, selectedPageIndex: 4)

        assertSelfSizingSnapshot(of: sut)
    }

    @Test
    func testOnboardingDotsIndexView_With3PagesAnd2ndSelected_LayoutsCorrectly() {
        let sut = OnboardingDotsIndexView(pagesCount: 3, selectedPageIndex: 1)

        assertSelfSizingSnapshot(of: sut)
    }

    @Test
    func testOnboardingDotsIndexView_With2PagesAnd1stSelected_LayoutsCorrectly() {
        let sut = OnboardingDotsIndexView(pagesCount: 2, selectedPageIndex: 0)

        assertSelfSizingSnapshot(of: sut)
    }

}

private extension OnboardingDotsIndexView {

    init(pagesCount: Int, selectedPageIndex: Int) {
        self.init(pagesCount: pagesCount, selectedPageIndex: selectedPageIndex, onTap: { _ in })
    }

}
