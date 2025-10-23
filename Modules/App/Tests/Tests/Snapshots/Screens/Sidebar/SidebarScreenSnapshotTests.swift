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
import UIKit
import proton_app_uniffi

@MainActor
final class SidebarScreenSnapshotTests {

    private let bundleStub = BundleStub(infoDictionary: .infoDictionaryWithAppVersion)

    private let state = SidebarState(
        upsell: .upsell(.standard),
        system: [],
        labels: [],
        folders: [],
        other: .staleItems,
        createLabel: .createLabel,
        createFolder: .createFolder
    )

    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func testSidebarWithDataLayoutsCorrectOnIphoneX(style: UIUserInterfaceStyle) {
        var state = self.state

        state.folders = [SidebarCustomFolder.topSecretFolder].map(\.sidebarFolder)
        state.system = [PMSystemLabel.inbox, .sent, .outbox].compactMap(\.sidebarSystemFolder)
        state.labels = [SidebarCustomLabel.importantLabel, .topSecretLabel].map(\.sidebarLabel)

        let sidebarScreen = SidebarScreen(
            state: state,
            userSession: .dummy,
            upsellEligibilityPublisher: .init(constant: .eligible(.standard)),
            appVersionProvider: .init(bundle: bundleStub, sdkVersionProvider: .init(sdkVersion: "0.61.0")),
            sidebarFactory: { _ in SidebarSpy() }
        ) { _ in }
        .environmentObject(AppUIStateStore(sidebarState: .init(zIndex: .zero, visibleWidth: 320)))

        assertSnapshotsOnIPhoneX(of: sidebarScreen, styles: [style])
    }

    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func testSidebarWithoutDynamicDataLayoutsCorrectlyOnIphoneX(style: UIUserInterfaceStyle) {
        var state = self.state

        state.system = [PMSystemLabel.inbox, .sent].compactMap(\.sidebarSystemFolder)

        let sidebarScreen = SidebarScreen(
            state: state,
            userSession: .dummy,
            upsellEligibilityPublisher: .init(constant: .eligible(.standard)),
            appVersionProvider: .init(bundle: bundleStub, sdkVersionProvider: .init(sdkVersion: "0.61.0")),
            sidebarFactory: { _ in SidebarSpy() }
        ) { _ in }
        .environmentObject(AppUIStateStore(sidebarState: .init(zIndex: .zero, visibleWidth: 320)))

        assertSnapshotsOnIPhoneX(of: sidebarScreen, styles: [style])
    }

}

private extension Dictionary where Key == String, Value == Any {

    static var infoDictionaryWithAppVersion: Self {
        [
            "CFBundleVersion": "20",
            "CFBundleShortVersionString": "0.1.0",
        ]
    }

}
