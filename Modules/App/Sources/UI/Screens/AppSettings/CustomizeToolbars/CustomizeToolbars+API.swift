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

struct CustomizeToolbarActions {
    let list: ToolbarActions
    let conversation: ToolbarActions
}

struct ToolbarActions {
    let selected: [ToolbarActionType]
    let unselected: [ToolbarActionType]
}

// Check the actions against AC
enum ToolbarActionType {
    case markAsUnread
    case moveToTrash
    case moveTo
    case labelAs
    case snooze
    case star
    case archive
    case moveToSpam
}

protocol ToolbarServiceProtocol: Sendable {
    func customizeToolbarActions() async throws -> CustomizeToolbarActions
}

struct ToolbarService: ToolbarServiceProtocol {

    func customizeToolbarActions() async throws -> CustomizeToolbarActions {
        .init(
            list: .init(
                selected: [.markAsUnread, .moveTo, .snooze, .archive],
                unselected: [.moveToTrash, .labelAs, .star, .moveToSpam]
            ),
            conversation: .init(
                selected: [.moveToTrash, .labelAs, .star, .moveToSpam, .archive],
                unselected: [.markAsUnread, .moveTo, .snooze]
            )
        )
    }

}
