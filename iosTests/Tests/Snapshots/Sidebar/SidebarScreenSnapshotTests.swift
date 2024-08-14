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

class SidebarScreenSnapshotTests: XCTestCase {

    func testSidebarWithDataLayoutsCorrectOnIphoneX() {
        let bundleStub = BundleStub(infoDictionary: .infoDictionaryWithAppVersion)
        let screenModel = SidebarModel(
            state: .init(
                system: .systemFolders.selectFirst(),
                labels: .labels, 
                folders: .folders,
                other: .staleItems,
                createLabel: .createLabel,
                createFolder: .createFolder
            ),
            dependencies: .init(activeUserSession: MailUserSessionSpy())
        )
        let sidebarScreen = SidebarScreen(screenModel: screenModel) { _ in }
            .environmentObject(AppUIState(isSidebarOpen: true))
            .environment(\.mainBundle, bundleStub)
        assertSnapshotsOnIPhoneX(of: sidebarScreen)
    }

    func testSidebarWithoutDynamicDataLayoutsCorrectlyOnIphoneX() {
        let bundleStub = BundleStub(infoDictionary: .infoDictionaryWithAppVersion)
        let screenModel = SidebarModel(
            state: .init(
                system: .systemFolders.selectFirst(),
                labels: [],
                folders: [],
                other: .staleItems,
                createLabel: .createLabel,
                createFolder: .createFolder
            ),
            dependencies: .init(activeUserSession: MailUserSessionSpy())
        )
        let sidebarScreen = SidebarScreen(screenModel: screenModel) { _ in }
            .environmentObject(AppUIState(isSidebarOpen: true))
            .environment(\.mainBundle, bundleStub)
        assertSnapshotsOnIPhoneX(of: sidebarScreen)
    }

}

private extension Array where Element == SidebarSystemFolder {

    func selectFirst() -> [Element] {
        enumerated()
            .map { index, element in element.copy(isSelected: index == 0) }
    }

}

import DesignSystem

private extension Array where Element == SidebarFolder {

    static var folders: [Element] {
        [
            .init(
                id: 2,
                parentID: nil,
                name: "Random",
                color: "#F78400",
                unreadCount: 100,
                expanded: true,
                isSelected: false
            ),
            .init(
                id: 3,
                parentID: 1,
                name: "Top Secret",
                color: "#179FD9",
                unreadCount: 5,
                expanded: true,
                isSelected: false
            ),
            .init(
                id: 4,
                parentID: 3,
                name: "Top Top Secret",
                color: "#1DA583",
                unreadCount: 9999,
                expanded: true,
                isSelected: false
            ),
            .init(
                id: 1,
                parentID: nil,
                name: "Secret",
                color: "#EC3E7C",
                unreadCount: 10,
                expanded: true,
                isSelected: false
            )
        ]
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
