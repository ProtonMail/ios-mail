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
import SnapshotTesting
import SwiftUI
import XCTest

class SidebarScreenSnapshotTests: XCTestCase {

    func testSidebarLayoutsCorrectOnIphoneX() {
        let bundleStub = BundleStub(infoDictionary: .infoDictionaryWithAppVersion)
        let screenModel = SidebarModel(
            state: .init(system: .systemFolders.selectFirst(), labels: .labels, other: .staleItems),
            dependencies: .init(activeUserSession: MailUserSessionSpy())
        )
        let sidebarScreen = SidebarScreen(screenModel: screenModel) { _ in }
            .environmentObject(AppUIState(isSidebarOpen: true))
            .environment(\.mainBundle, bundleStub)
        assertSnapshot(of: UIHostingController(rootView: sidebarScreen), as: .image(on: .iPhoneX))
    }

}

private extension Array where Element == SidebarSystemFolder {

    func selectFirst() -> [Element] {
        enumerated()
            .map { index, element in element.copy(isSelected: index == 0) }
    }

}

private extension Dictionary where Key == String, Value == Any {

    static var infoDictionaryWithAppVersion: Self {
        [
            "CFBundleVersion": "20",
            "CFBundleShortVersionString": "0.1.0"
        ]
    }

}

private class BundleStub: Bundle {

    private let _infoDictionary: [String : Any]?

    init(infoDictionary: [String : Any]?) {
        self._infoDictionary = infoDictionary
        super.init()
    }

    override var infoDictionary: [String : Any]? {
        _infoDictionary
    }

}
