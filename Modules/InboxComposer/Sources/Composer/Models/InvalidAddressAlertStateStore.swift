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

final class InvalidAddressAlertStateStore {
    let recipientAddressValidator: EditingRecipientAddressValidator
    let alertBinding: Binding<AlertModel?>

    init(validator: EditingRecipientAddressValidator, alertBinding: Binding<AlertModel?>) {
        self.recipientAddressValidator = validator
        self.alertBinding = alertBinding
    }

    var isAlertShown: Bool {
        alertBinding.wrappedValue != nil
    }

    @discardableResult
    func validateAndShowAlertIfNeeded() -> Bool {
        let isValid = recipientAddressValidator.validateFormatAddress()
        if !isValid {
            alertBinding.wrappedValue = .invalidAddressFormat(action: {
                [weak self] in self?.alertBinding.wrappedValue = nil
            })
        }
        return isValid
    }
}

private extension AlertModel {
    static func invalidAddressFormat(action: @escaping () -> Void) -> Self {
        let actions: [AlertAction] = [.init(details: InvalidAddressFormatAlertAction.close, action: action)]

        return .init(
            title: L10n.ComposerError.invalidAddressFormatTitle,
            message: L10n.ComposerError.invalidAddressFormatMessage,
            actions: actions
        )
    }
}

private enum InvalidAddressFormatAlertAction: AlertActionInfo, CaseIterable {
    case close

    var info: (title: LocalizedStringResource, buttonRole: ButtonRole?) {
        switch self {
        case .close:
            (CommonL10n.gotIt, .cancel)
        }
    }
}
