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

import proton_app_uniffi

@testable import ProtonMail

extension PMCustomFolder {

    static var topSecretFolder: Self {
        .testData(id: 5, name: "Top Secret", color: "#F78400", children: [.hiddenFolder], unread: 9999)
    }

    static var hiddenFolder: Self {
        .testData(id: 6, name: "Hidden", color: "#EC3E7C", children: [.superPrivate], unread: 0)
    }

    static var superPrivate: Self {
        .testData(id: 7, name: "Super Private", color: "#179FD9", unread: 5)
    }

    static func testData(
        id: UInt64 = UInt64.random(in: 1...UInt64.max),
        name: String,
        color: String = "#000000",
        children: [SidebarCustomFolder] = [],
        unread: UInt64 = 0
    ) -> SidebarCustomFolder {
        .init(
            id: .init(value: id),
            parentId: nil,
            children: children,
            color: .init(value: color),
            description: .folder,
            display: false,
            expanded: true,
            name: name,
            notify: false,
            displayOrder: 0,
            path: nil,
            sticky: false,
            total: 0,
            unread: unread
        )
    }

}
