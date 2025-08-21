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

import InboxCore
import InboxCoreUI
import SwiftUI

extension AlertModel {

    static func editScheduleConfirmation(action: @escaping @MainActor (EditScheduleAlertAction) async -> Void) -> Self {
        .init(
            title: L10n.Action.Send.editScheduledAlertTitle,
            message: L10n.Action.Send.editScheduledAlertMessage,
            actions: alertActions(action: action)
        )
    }

    static func deleteConfirmation(
        itemsCount: Int,
        action: @escaping @MainActor @Sendable (DeleteConfirmationAlertAction) async -> Void
    ) -> Self {
        .init(
            title: L10n.Action.Delete.Alert.title(itemsCount: itemsCount),
            message: L10n.Action.Delete.Alert.message(itemsCount: itemsCount),
            actions: alertActions(action: action)
        )
    }

    static func phishingConfirmation(action: @escaping (PhishingConfirmationAlertAction) async -> Void) -> Self {
        .init(
            title: L10n.Action.ReportPhishing.Alert.title,
            message: L10n.Action.ReportPhishing.Alert.message,
            actions: alertActions(action: action)
        )
    }

    static func openURLConfirmation(url: URL, action: @escaping @MainActor (ConfirmLinkAlertAction) -> Void) -> Self {
        .init(
            title: L10n.ConfirmLink.title,
            message: url.absoluteString.stringResource,
            actions: alertActions(action: action)
        )
    }

    private static func alertActions<ActionType: AlertActionInfo & CaseIterable & Sendable>(
        action: @escaping @MainActor (ActionType) async -> Void
    ) -> [AlertAction] {
        ActionType.allCases.map { actionType in
            .init(details: actionType, action: { await action(actionType) })
        }
    }

}
