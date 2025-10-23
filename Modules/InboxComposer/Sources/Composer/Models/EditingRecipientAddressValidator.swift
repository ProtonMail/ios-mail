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

struct EditingRecipientAddressValidator {
    let readState: () -> ComposerState?
    let composerWillDismiss: () -> Bool

    init(
        readState: @escaping () -> ComposerState?,
        composerWillDismiss: @escaping () -> Bool
    ) {
        self.readState = readState
        self.composerWillDismiss = composerWillDismiss
    }

    func canResignFocus() -> Bool {
        if composerWillDismiss() { return true }
        return isInputValidFormatAddress()
    }

    func validateFormatAddress() -> Bool {
        return isInputValidFormatAddress()
    }

    private func isInputValidFormatAddress() -> Bool {
        guard let editingRecipient = readState()?.editingRecipientFieldState else { return true }
        if editingRecipient.controllerState == .editing {
            let trimmedInput = editingRecipient.input.withoutWhitespace
            let singleRecipient = newRecipient(email: trimmedInput)
            return trimmedInput.isEmpty || isValidEmailAddress(address: singleRecipient.email)
        }
        return true
    }
}
