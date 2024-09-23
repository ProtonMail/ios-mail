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
import XCTest

class OnboardingDotsIndexViewSnapshotTests: BaseTestCase {

    func testOnboardingDotsIndexView_With5PagesAnd5thSelected_LayoutsCorrectly() {
        let sut = OnboardingDotsIndexView(numberOfPages: 5, currentPageIndex: 4)

        assertSelfSizingSnapshot(of: sut)
    }

    func testOnboardingDotsIndexView_With3PagesAnd2ndSelected_LayoutsCorrectly() {
        let sut = OnboardingDotsIndexView(numberOfPages: 3, currentPageIndex: 1)

        assertSelfSizingSnapshot(of: sut)
    }

    func testOnboardingDotsIndexView_With2PagesAnd1stSelected_LayoutsCorrectly() {
        let sut = OnboardingDotsIndexView(numberOfPages: 2, currentPageIndex: 0)

        assertSelfSizingSnapshot(of: sut)
    }

}

private extension OnboardingDotsIndexView {

    init(numberOfPages: Int, currentPageIndex: Int) {
        self.init(numberOfPages: numberOfPages, currentPageIndex: currentPageIndex, onTap: { _ in })
    }

}
