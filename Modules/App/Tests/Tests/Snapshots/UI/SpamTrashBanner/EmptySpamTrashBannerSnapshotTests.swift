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
import InboxSnapshotTesting
import InboxTesting
import Testing
import SwiftUI
import XCTest

@MainActor
struct EmptySpamTrashBannerViewSnapshotTests {
    struct TestCase {
        let location: EmptySpamTrashBanner.Location
        let userState: EmptySpamTrashBanner.UserState
        
        init(_ location: EmptySpamTrashBanner.Location, _ userState: EmptySpamTrashBanner.UserState) {
            self.location = location
            self.userState = userState
        }
    }
    
    @Test(
        "all snapshot variants",
        arguments: [
            TestCase(.spam, .freePlan),
            TestCase(.spam, .paidAutoDeleteOff),
            TestCase(.spam, .paidAutoDeleteOn),
            TestCase(.trash, .freePlan),
            TestCase(.trash, .paidAutoDeleteOff),
            TestCase(.trash, .paidAutoDeleteOn),
        ])
    func snapshotAllVariants(_ testCase: TestCase) {
        let snapshotSuffix = "\(testCase.location)_\(testCase.userState)"
        assertSnapshotsOnIPhoneX(of: sut(testCase.location, testCase.userState), named: snapshotSuffix)
    }
    
    private func sut(
        _ location: EmptySpamTrashBanner.Location,
        _ userState: EmptySpamTrashBanner.UserState
    ) -> some View {
        EmptySpamTrashBannerView(model: .init(location: location, userState: userState))
            .environmentObject(ToastStateStore(initialState: .initial))
            .padding([.leading, .trailing], DS.Spacing.medium)
    }
}
