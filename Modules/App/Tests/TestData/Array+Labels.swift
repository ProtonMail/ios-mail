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

extension Array where Element == SidebarLabel {

    static var labels: [Element] {
        [
            .init(id: .init(value: 3), color: "#A4A4AB", name: "Important", unreadCount: "10", isSelected: false),
            .init(id: .init(value: 4), color: "#9292F9", name: "Work", unreadCount: "1", isSelected: false)
        ]
    }

}
