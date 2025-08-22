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

import InboxCore

struct ToolbarsActions {
    var list: CustomizeToolbarActions
    var message: CustomizeToolbarActions
    var conversation: CustomizeToolbarActions
}

struct CustomizeToolbarActions {
    var selected: [MobileAction]
    var unselected: [MobileAction]
}

struct CustomizeToolbarState: Copying {
    var toolbars: [ToolbarWithActions]
    var editToolbar: ToolbarType?
}

enum ToolbarWithActions {
    case list(CustomizeToolbarActions)
    case message(CustomizeToolbarActions)
    case conversation(CustomizeToolbarActions)

    var actions: CustomizeToolbarActions {
        switch self {
        case .list(let actions), .message(let actions), .conversation(let actions):
            actions
        }
    }
}

import proton_app_uniffi


extension CustomizeToolbarState {
    static var initial: Self {
        .init(toolbars: [], editToolbar: nil)
    }
}

enum CustomizeToolbarsDisplayItem {
    case action(MobileAction)
    case editActions
}
