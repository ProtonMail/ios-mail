// Copyright (c) 2022 Proton AG
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
import ProtonCore_Networking

struct UpdateToolbarActionSettingRequest: Request {
    let path = "\(SettingsAPI.path)/mobilesettings"
    let method: HTTPMethod = .put
    private let messageViewActions: [ServerToolbarAction]?
    private let conversationViewActions: [ServerToolbarAction]?
    private let listViewActions: [ServerToolbarAction]?

    var parameters: [String: Any]? {
        var out: [String: Any] = [:]
        if let actions = messageViewActions {
            out["MessageToolbar"] = actions.map(\.rawValue)
        }
        if let actions = conversationViewActions {
            out["ConversationToolbar"] = actions.map(\.rawValue)
        }
        if let actions = listViewActions {
            out["ListToolbar"] = actions.map(\.rawValue)
        }
        return out
    }

    init?(message: [ServerToolbarAction]?,
          conversation: [ServerToolbarAction]?,
          listView: [ServerToolbarAction]?) {
        guard message != nil || conversation != nil || listView != nil else {
            return nil
        }
        messageViewActions = message
        conversationViewActions = conversation
        listViewActions = listView
    }
}
