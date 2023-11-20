// Copyright (c) 2023 Proton Technologies AG
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

import Foundation

struct LabelResponse: Decodable {
    let id: String
    let action: Int
    let label: Label?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case action = "Action"
        case label = "Label"
    }

    struct Label: Decodable {
        let id: String
        let name: String
        let path: String
        let type: Int
        let color: String
        let order: Int
        let notify: Int
        let expanded: Int
        let sticky: Int
        let display: Int
        let parentId: String?

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case name = "Name"
            case path = "Path"
            case type = "Type"
            case color = "Color"
            case order = "Order"
            case notify = "Notify"
            case expanded = "Expanded"
            case sticky = "Sticky"
            case display = "Display"
            case parentId = "ParentID"
        }
    }
}
