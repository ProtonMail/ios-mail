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
import InboxTesting
import XCTest

class MessageDetailsViewSnapshotTests: BaseTestCase {

    func testMessageDetailsWithInboxLocationLayoutsCorrectly() {
        let model = MessageDetailsPreviewProvider.testData(
            location: .system(.inbox),
            labels: [
                .init(labelId: .init(value: 1), text: "Reminder", color: .init(hex: "#F67900")),
                .init(labelId: .init(value: 2), text: "Private", color: .init(hex: "#E93671")),
                .init(labelId: .init(value: 3), text: "Summer trip", color: .init(hex: "#9E329A")),
            ]
        )

        assertSnapshotsOnIPhoneX(of: sut(collapsed: true, model: model), named: "collapsed")
        assertSnapshotsOnIPhoneX(of: sut(collapsed: false, model: model), named: "expanded")
    }

    func testMessageDetailsWithArchiveLocationNoLabelsLayoutsCorrectly() {
        let model = MessageDetailsPreviewProvider.testData(
            location: .system(.archive),
            labels: []
        )

        assertSnapshotsOnIPhoneX(of: sut(collapsed: true, model: model), named: "collapsed")
        assertSnapshotsOnIPhoneX(of: sut(collapsed: false, model: model), named: "expanded")
    }

    func testMessageDetailsWithCustomLocationAndLabelsLayoutsCorrectly() {
        let model = MessageDetailsPreviewProvider.testData(
            location: .custom(name: "Online shopping", id: .random(), color: .init(value: "#F67900")),
            labels: [
                .init(labelId: .init(value: 1), text: "Friends and Family", color: .init(hex: "#1795D4")),
                .init(labelId: .init(value: 2), text: "Work", color: .init(hex: "#F67900")),
                .init(labelId: .init(value: 3), text: "Personal", color: .init(hex: "#E93671")),
                .init(labelId: .init(value: 4), text: "Shopping", color: .init(hex: "#1B9B78"))
            ]
        )

        assertSnapshotsOnIPhoneX(of: sut(collapsed: true, model: model), named: "collapsed")
        assertSnapshotsOnIPhoneX(of: sut(collapsed: false, model: model), named: "expanded")
    }

    func testMessageDetailsWithOutboxLocationLayoutsCorrectly() {
        let model = MessageDetailsPreviewProvider.testData(location: .system(.outbox), labels: [])
        assertSnapshotsOnIPhoneX(of: sut(collapsed: false, model: model, isOutbox: true))
    }

    private func sut(collapsed: Bool, model: MessageDetailsUIModel, isOutbox: Bool = false) -> MessageDetailsView {
        .init(isHeaderCollapsed: collapsed, uiModel: model, isOutbox: isOutbox, onEvent: { _ in })
    }

}
