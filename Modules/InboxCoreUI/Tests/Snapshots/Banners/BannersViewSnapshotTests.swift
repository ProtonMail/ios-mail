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

import InboxDesignSystem
import InboxSnapshotTesting
import InboxTesting
import XCTest

@testable import InboxCoreUI

class BannersViewSnapshotTests: BaseTestCase {
    func testBannersViewLayoutsCorrectly() {
        let bannersView = BannersView(model: [
            .init(
                icon: DS.Icon.icFire,
                title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                subtitle: nil,
                size: .small(nil),
                style: .regular
            ),
            .init(
                icon: DS.Icon.icFire,
                title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                subtitle: nil,
                size: .small(nil),
                style: .error
            ),
            .init(
                icon: DS.Icon.icCogWheel,
                title: "Lorem ipsum dolor sit amet.",
                subtitle: nil,
                size: .small(.button(.init(title: "Action", action: {}))),
                style: .regular
            ),
            .init(
                icon: DS.Icon.icCogWheel,
                title: "Lorem ipsum dolor sit amet.",
                subtitle: nil,
                size: .small(.button(.init(title: "Action", action: {}))),
                style: .error
            ),
            .init(
                icon: DS.Icon.icTrash,
                title: "Show trashed messages in this conversation.",
                subtitle: nil,
                size: .small(.toggle(.init(title: "Action", isOn: .readonly(get: { true })))),
                style: .regular
            ),
            .init(
                icon: DS.Icon.icHook,
                title: "Lorem ipsum dolor sit amet.",
                subtitle: nil,
                size: .small(nil),
                style: .regular
            ),
            .init(
                icon: DS.Icon.icHook,
                title: "Lorem ipsum dolor sit amet.",
                subtitle: nil,
                size: .small(nil),
                style: .error
            ),
            .init(
                icon: DS.Icon.icCogWheel,
                title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                subtitle: nil,
                size: .large(.one(.init(title: "One button action", action: {}))),
                style: .regular
            ),
            .init(
                icon: DS.Icon.icCogWheel,
                title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                subtitle: nil,
                size: .large(
                    .two(
                        left: .init(title: "Left", action: {}),
                        right: .init(title: "Right", action: {})
                    )),
                style: .error
            ),
        ])

        assertSnapshotsOnIPhoneX(of: bannersView)
    }
}
