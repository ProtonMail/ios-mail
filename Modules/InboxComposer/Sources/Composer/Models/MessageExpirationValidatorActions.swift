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
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

struct MessageExpirationValidatorActions {
    let validate: @MainActor (_ draft: AppDraftProtocol, _ alertBinding: Binding<AlertModel?>) async -> MessageExpiryValidationResult

    static var productionInstance: Self {
        .init(validate: { draft, alertBinding in
            await productionValidateRecipientsIfMessageHasExpiration(draft: draft, alertBinding: alertBinding)
        })
    }

    static func dummy(returning result: MessageExpiryValidationResult) -> Self {
        .init(validate: { _, _ in
            result
        })
    }
}

private extension MessageExpirationValidatorActions {

    @MainActor
    static func productionValidateRecipientsIfMessageHasExpiration(
        draft: AppDraftProtocol,
        alertBinding: Binding<AlertModel?>
    ) async -> MessageExpiryValidationResult {
        do {
            guard try draft.expirationTime().get() != .never else { return .proceed }

            let report = try draft.validateRecipientsExpirationFeature().get()
            guard let messageToWarnUser = messageToShowUser(for: report) else { return .proceed }

            return await withCheckedContinuation { (continuation: CheckedContinuation<MessageExpiryValidationResult, Never>) in
                alertBinding.wrappedValue = .expiringMessageUnsupported(message: messageToWarnUser) { action in
                    alertBinding.wrappedValue = nil
                    switch action {
                    case .sendAnyway:
                        continuation.resume(returning: .proceed)
                    case .addPassword:
                        continuation.resume(returning: .doNotProceed(addPassword: true))
                    case .cancel:
                        continuation.resume(returning: .doNotProceed(addPassword: false))
                    }
                }
            }
        } catch {
            AppLogger.log(error: error, category: .composer)
            return .doNotProceed(addPassword: false)
        }
    }

    static func messageToShowUser(for report: DraftRecipientExpirationFeatureReport) -> LocalizedStringResource? {
        var messageToShowUser: LocalizedStringResource?
        if !report.unsupported.isEmpty {
            if report.supported.isEmpty && report.unknown.isEmpty {
                messageToShowUser = L10n.MessageExpiration.alertUnsupportedForAllRecipientsMessage
            } else {
                messageToShowUser = L10n
                    .MessageExpiration
                    .alertUnsupportedForSomeRecipientsMessage(
                        addresses: report.unsupported.joined(separator: ", ")
                    )
            }
        } else if !report.unknown.isEmpty {
            messageToShowUser = L10n.MessageExpiration.alertUnknownSupportForAllRecipientsMessage
        }
        return messageToShowUser
    }
}
