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
import proton_mail_uniffi

extension LocalLabelWithCount {

    static let inbox = LocalLabelWithCount.testData(
        id: 1,
        rid: "\(SystemFolderIdentifier.inbox.rawValue)",
        name: "Inbox",
        type: .system
    )
    static let sent = LocalLabelWithCount.testData(
        id: 2,
        rid: "\(SystemFolderIdentifier.sent.rawValue)",
        name: "Sent",
        type: .system
    )
    static let importantLabel: Self = .testData(id: 3, name: "Important", color: "#111111", type: .label)
    static let topSecretLabel: Self = .testData(id: 4, name: "Top Secret", color: "#222222", type: .label)

    static let topSecretFolder: Self = .testData(id: 5, name: "Top Secret", color: "#333333", type: .folder)
    static let hiddenFolder: Self = .testData(id: 6, parentId: 5, name: "Hidden", color: "#444444", type: .folder)

    static func testData(
        id: UInt64,
        rid: String? = nil,
        parentId: UInt64? = nil,
        name: String,
        color: String = "#000000",
        type: LabelType
    ) -> Self {
        .init(
            id: id,
            rid: rid,
            parentId: parentId,
            name: name,
            path: nil,
            color: color,
            labelType: type,
            order: 0,
            notified: false,
            expanded: false,
            sticky: false,
            totalCount: 0,
            unreadCount: 0
        )
    }

}
