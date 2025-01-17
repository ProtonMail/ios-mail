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
import proton_app_uniffi

extension PMSystemLabel {

    static let inbox: Self = .testData(id: 1, systemLabel: .inbox, name: "Inbox")
    static let sent: Self = .testData(id: 2, systemLabel: .sent, name: "Sent")
    static let outbox: Self = .testData(id: 3, systemLabel: .outbox, name: "Outbox")

    static func testData(
        id: UInt64 = UInt64.random(in: 1...UInt64.max),
        systemLabel: SystemLabel?,
        parentId: UInt64? = nil,
        name: String,
        color: String = "#000000",
        displayOrder: UInt32 = UInt32.random(in: 1...UInt32.max)
    ) -> Self {
        .init(
            id: .init(value: id),
            display: false,
            description: .system(systemLabel),
            name: name,
            notify: false,
            displayOrder: displayOrder,
            sticky: false,
            total: 0,
            unread: 0
        )
    }

}
