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
import InboxDesignSystem
import InboxSnapshotTesting
import InboxTesting
import Testing
import SwiftUI
import XCTest

@MainActor
struct EmptySpamTrashBannerViewSnapshotTests {
    @Test
    func testSpamForFreeUserLayoutsCorrectly() {
        assertSnapshotsOnIPhoneX(of: sut(.spam, .freePlan))
    }
    
    @Test
    func testSpamForPaidUserAutoDeleteOffLayoutsCorrectly() {
        assertSnapshotsOnIPhoneX(of: sut(.spam, .paidAutoDeleteOff))
    }
    
    @Test
    func testSpamForPaidUserAutoDeleteOnLayoutsCorrectly() {
        assertSnapshotsOnIPhoneX(of: sut(.spam, .paidAutoDeleteOn))
    }
    
    @Test
    func testTrashFreeUserLayoutsCorrectly() {
        assertSnapshotsOnIPhoneX(of: sut(.trash, .freePlan))
    }
    
    @Test
    func testTrashForPaidUserAutoDeleteOffLayoutsCorrectly() {
        assertSnapshotsOnIPhoneX(of: sut(.trash, .paidAutoDeleteOff))
    }
    
    @Test
    func testTrashForPaidUserAutoDeleteOnLayoutsCorrectly() {
        assertSnapshotsOnIPhoneX(of: sut(.trash, .paidAutoDeleteOn))
    }
    
    private func sut(
        _ location: EmptySpamTrashBanner.Location,
        _ userState: EmptySpamTrashBanner.UserState
    ) -> some View {
        EmptySpamTrashBannerView(model: .init(location: location, userState: userState))
            .padding([.leading, .trailing], DS.Spacing.medium)
    }
}
