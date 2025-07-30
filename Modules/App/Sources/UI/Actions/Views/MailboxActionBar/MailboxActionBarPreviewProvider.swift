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

enum MailboxActionBarPreviewProvider {

    static func state() -> MailboxActionBarState {
        MailboxActionBarState(
            bottomBarActions: [
                .markRead,
                .moveTo,
                .labelAs,
                .moveToSystemFolder(.init(localId: .init(value: 1), name: .archive)),
                .more
            ],
            moreSheetOnlyActions: [
                .notSpam(.init(localId: .init(value: 1), name: .inbox)), .permanentDelete, .star
            ],
            moreActionSheetPresented: nil,
            labelAsSheetPresented: nil,
            moveToSheetPresented: nil,
            isSnoozeSheetPresented: false
        )
    }

    static func availableActions() -> AvailableMailboxActionBarActions {
        let stub = AllBottomBarMessageActions(
            hiddenBottomBarActions: [],
            visibleBottomBarActions: [
                .markRead,
                .moveTo,
                .labelAs,
                .moveToSystemFolder(.init(localId: .init(value: 7), name: .archive)),
                .more
            ]
        )
        return .init(
            message: { _, _ in .ok(stub) },
            conversation: { _, _ in .ok(stub) }
        )
    }

}
