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

import InboxCoreUI

extension AlertViewModel {

    static func deleteConfirmation(
        itemsCount: Int,
        action: @escaping (DeleteConfirmationAlertAction) -> Void
    ) -> AlertViewModel {
        .init(
            title: L10n.Action.Delete.Alert.title(itemsCount: itemsCount),
            message: L10n.Action.Delete.Alert.message(itemsCount: itemsCount),
            actions: [.cancel(action: { action(.cancel) }), .delete(action: { action(.delete) })]
        )
    }

}

private extension AlertAction {

    static func cancel(action: @escaping () -> Void) -> AlertAction {
        AlertAction(title: L10n.Common.cancel, buttonRole: .cancel, action: action)
    }

    static func delete(action: @escaping () -> Void) -> AlertAction {
        AlertAction(title: L10n.Common.delete, buttonRole: .destructive, action: action)
    }

}
