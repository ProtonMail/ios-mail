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

import Foundation
import InboxCore
import InboxCoreUI
import SwiftUI

extension AlertModel {

    static func discardDraft(action: @escaping @MainActor (DiscardDraftAlertAction) async -> Void) -> Self {
        let actions: [AlertAction] = DiscardDraftAlertAction.allCases.map { actionType in
            .init(details: actionType, action: { await action(actionType) })
        }

        return .init(
            title: L10n.Composer.discardConfirmationTitle,
            message: L10n.Composer.discardConfirmationMessage,
            actions: actions
        )
    }

    static func expiringMessageUnsupported(message: LocalizedStringResource, action: @escaping @MainActor (ExpiringMessageUnsupportedAlertAction) async -> Void) -> Self {
        let actions: [AlertAction] = ExpiringMessageUnsupportedAlertAction.allCases.map { actionType in
            .init(details: actionType, action: { await action(actionType) })
        }

        return .init(
            title: L10n.MessageExpiration.alertUnsupportedTitle,
            message: message,
            actions: actions
        )
    }

    static func senderAddressCannotSend(message: LocalizedStringResource, onDismiss: @escaping () -> Void) -> Self {
        struct Action: AlertActionInfo {
            var info: (title: LocalizedStringResource, buttonRole: ButtonRole?)
        }
        return .init(
            title: L10n.SenderValidation.addressNotAvailableAlertTitle,
            message: message,
            actions: [
                .init(
                    details: Action(info: (title: CommonL10n.ok, buttonRole: .cancel)),
                    action: { onDismiss() }
                )
            ]
        )
    }
}
