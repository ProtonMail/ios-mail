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

import InboxSnapshotTesting
import Testing

@testable import ProtonMail

@MainActor
struct PrintHeaderViewSnapshotTests {
    @Test
    func printHeaderView() {
        let messageDetails = MessageDetailsPreviewProvider.testData(
            location: .system(name: .inbox, id: 0),
            labels: [
                .init(labelId: 0, text: "foo", color: .red),
                .init(labelId: 0, text: "bar", color: .blue),
            ]
        )

        let sut = PrintHeaderView(
            subject: "Some very very long subject that will totally get carried to a new line",
            messageDetails: messageDetails
        )

        assertSnapshotsOnIPhoneX(of: sut)
    }
}
