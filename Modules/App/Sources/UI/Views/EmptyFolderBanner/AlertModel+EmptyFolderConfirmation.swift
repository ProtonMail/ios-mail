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

import InboxCoreUI
import proton_app_uniffi

extension AlertModel {
    static func emptyFolderConfirmation(
        folder: SpamOrTrash,
        action: @escaping (DeleteConfirmationAlertAction) async -> Void
    ) -> Self {
        let actions: [AlertAction] = DeleteConfirmationAlertAction.allCases.map { actionType in
            .init(details: actionType, action: { await action(actionType) })
        }

        return .init(
            title: L10n.EmptyFolderBanner.Alert.emptyFolderTitle(folderName: folder.humanReadable),
            message: L10n.EmptyFolderBanner.Alert.emptyFolderMessage(folderName: folder.humanReadable),
            actions: actions
        )
    }
}
