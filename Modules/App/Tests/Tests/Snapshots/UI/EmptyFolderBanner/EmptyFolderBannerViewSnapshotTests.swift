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

@testable import ProtonMail
import InboxCoreUI
import InboxDesignSystem
import InboxIAP
import InboxSnapshotTesting
import proton_app_uniffi
import ProtonUIFoundations
import SwiftUI
import Testing
import XCTest

@MainActor
struct EmptyFolderBannerViewSnapshotTests {
    struct TestCase {
        let folder: SpamOrTrash
        let state: AutoDeleteState

        init(_ folder: SpamOrTrash, _ state: AutoDeleteState) {
            self.folder = folder
            self.state = state
        }
    }

    @Test(
        "all snapshot variants",
        arguments: [
            TestCase(.spam, .autoDeleteUpsell),
            TestCase(.spam, .autoDeleteDisabled),
            TestCase(.spam, .autoDeleteEnabled),
            TestCase(.trash, .autoDeleteUpsell),
            TestCase(.trash, .autoDeleteDisabled),
            TestCase(.trash, .autoDeleteEnabled),
        ])
    func snapshotAllVariants(_ testCase: TestCase) {
        let snapshotSuffix = "\(testCase.folder)_\(testCase.state)"
        assertSnapshotsOnIPhoneX(of: sut(testCase.folder, testCase.state), named: snapshotSuffix)
    }

    private func sut(
        _ folder: SpamOrTrash,
        _ state: AutoDeleteState
    ) -> some View {
        EmptyFolderBannerView(
            model: .init(folder: .init(labelID: .random(), type: folder), userState: state),
            mailUserSession: .dummy,
            wrapper: .previewInstance()
        )
        .environmentObject(ToastStateStore(initialState: .initial))
        .environmentObject(UpsellCoordinator(mailUserSession: .dummy, configuration: .mail))
        .padding([.leading, .trailing], DS.Spacing.medium)
    }
}
