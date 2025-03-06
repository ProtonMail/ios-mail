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
import SwiftUI
import XCTest

class OnboardingScreenSnapshotTests: BaseTestCase {

    func testInitialStateLayoutsCorrecttly() {
        assertSnapshots(matching: makeSUT(selectedPageIndex: 0), on: .allPhones)
    }

    func test2ndPageSelectedLayoutsCorrecttly() {
        assertSnapshots(matching: makeSUT(selectedPageIndex: 1), on: .allPhones)
    }

    func test3rdPageSelectedLayoutsCorrecttly() {
        assertSnapshots(matching: makeSUT(selectedPageIndex: 2), on: .allPhones)
    }

    // MARK: - Private

    private func makeSUT(selectedPageIndex: Int) -> UIHostingController<OnboardingScreen> {
        let sut = OnboardingScreen(selectedPageIndex: selectedPageIndex)
        return UIHostingController(rootView: sut)
    }

}
