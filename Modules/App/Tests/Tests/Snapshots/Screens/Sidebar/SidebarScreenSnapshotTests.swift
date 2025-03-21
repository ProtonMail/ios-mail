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
import XCTest

class SidebarScreenSnapshotTests: BaseTestCase {

    var sidebarSpy: SidebarSpy!
    var state: SidebarState!
    private var bundleStub: BundleStub!

    override func setUp() {
        super.setUp()

        sidebarSpy = .init()
        state = SidebarState(
            system: [],
            labels: [],
            folders: [],
            other: .staleItems,
            createLabel: .createLabel,
            createFolder: .createFolder
        )
        bundleStub = BundleStub(infoDictionary: .infoDictionaryWithAppVersion)
    }

    override func tearDown() {
        sidebarSpy = nil
        bundleStub = nil

        super.tearDown()
    }

    func testSidebarWithDataLayoutsCorrectOnIphoneX() {
        sidebarSpy.stubbedCustomFolders = [.topSecretFolder]
        sidebarSpy.stubbedSystemLabels = [.inbox, .sent, .outbox]
        sidebarSpy.stubbedCustomLabels = [.importantLabel, .topSecretLabel]

        let sidebarScreen = SidebarScreen(
            state: state,
            userSession: .dummy,
            sidebarFactory: { _ in self.sidebarSpy! }
        ) { _ in }
            .environmentObject(AppUIStateStore(sidebarState: .init(zIndex: .zero, visibleWidth: 320)))
            .environment(\.mainBundle, bundleStub)
        assertSnapshotsOnIPhoneX(of: sidebarScreen)
    }

    func testSidebarWithoutDynamicDataLayoutsCorrectlyOnIphoneX() {
        sidebarSpy.stubbedSystemLabels = [.inbox, .sent]

        let sidebarScreen = SidebarScreen(
            state: state,
            userSession: .dummy,
            appVersionProvider: .init(bundle: bundleStub, sdkVersionProvider: .init(sdkVersion: "0.61.0") ),
            sidebarFactory: { _ in self.sidebarSpy! }
        ) { _ in }
            .environmentObject(AppUIStateStore(sidebarState: .init(zIndex: .zero, visibleWidth: 320)))
            .environment(\.mainBundle, bundleStub)
        assertSnapshotsOnIPhoneX(of: sidebarScreen)
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
