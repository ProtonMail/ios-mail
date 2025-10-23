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
import SwiftUI

struct SenderAddressValidatorActions {
    let validate: @MainActor (_ draft: AppDraftProtocol, _ alertBinding: Binding<AlertModel?>) async -> Void

    static var productionInstance: Self {
        .init(validate: { draft, alertBinding in
            await productionValidateSenderAddress(draft: draft, alertBinding: alertBinding)
        })
    }

    static func dummy() -> Self {
        .init(validate: { _, _ in })
    }
}

private extension SenderAddressValidatorActions {

    @MainActor
    static func productionValidateSenderAddress(
        draft: AppDraftProtocol,
        alertBinding: Binding<AlertModel?>
    ) async {
        guard let invalid = draft.addressValidationResult() else { return }
        draft.clearAddressValidationError()

        let invalidAddress = invalid.email
        let message = messageForError(invalid.error, address: invalidAddress)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            alertBinding.wrappedValue = .senderAddressCannotSend(
                message: message,
                onDismiss: {
                    alertBinding.wrappedValue = nil
                    continuation.resume()
                }
            )
        }
    }

    static func messageForError(_ error: DraftAddressValidationError, address: String) -> LocalizedStringResource {
        switch error {
        case .canNotSend, .canNotReceive:
            return L10n.SenderValidation.cannotSend(address: address)
        case .disabled:
            return L10n.SenderValidation.disabled(address: address)
        case .subscriptionRequired:
            return L10n.SenderValidation.subscriptionRequired(address: address)
        }
    }
}
