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
import ProtonCore_DataModel

extension UserManager: ToolbarActionProvider {
    var messageToolbarActions: [MessageViewActionSheetAction] {
        get {
            guard UserInfo.isToolbarCustomizationEnable else {
                return Constants.defaultToolbarActions
            }
            let serverActions = userInfo.messageToolbarActions.actions.compactMap({ ServerToolbarAction(rawValue: $0) })
            return MessageViewActionSheetAction.convert(from: serverActions)
        }
        set {
            let rawActions = ServerToolbarAction.convert(action: newValue)
            userInfo.messageToolbarActions.actions = rawActions.map { $0.rawValue }
        }
    }

    var conversationToolbarActions: [MessageViewActionSheetAction] {
        get {
            guard UserInfo.isToolbarCustomizationEnable else {
                return Constants.defaultToolbarActions
            }
            let serverActions = userInfo.conversationToolbarActions.actions
                .compactMap({ ServerToolbarAction(rawValue: $0) })
            return MessageViewActionSheetAction.convert(from: serverActions)
        }
        set {
            let rawActions = ServerToolbarAction.convert(action: newValue)
            userInfo.conversationToolbarActions.actions = rawActions.map { $0.rawValue }
        }
    }

    var listViewToolbarActions: [MessageViewActionSheetAction] {
        get {
            guard UserInfo.isToolbarCustomizationEnable else {
                return Constants.defaultToolbarActions
            }
            let serverActions = userInfo.listToolbarActions.actions.compactMap({ ServerToolbarAction(rawValue: $0) })
            return MessageViewActionSheetAction.convert(from: serverActions)
        }
        set {
            let rawActions = ServerToolbarAction.convert(action: newValue)
            userInfo.listToolbarActions.actions = rawActions.map { $0.rawValue }
        }
    }
}
