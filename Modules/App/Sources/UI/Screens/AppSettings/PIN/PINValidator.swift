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

struct PINValidator {
    private let pinScreenType: PINScreenType

    init(pinScreenType: PINScreenType) {
        self.pinScreenType = pinScreenType
    }

    // FIXME: - Add Rust SDK validation to it
    func validate(pin: String) -> FormTextInput.ValidationStatus {
        switch pinScreenType {
        case .set:
            setPINValidation(pin: pin)
        case .confirm(let pinToConfirm):
            confirmPINValidation(pin: pinToConfirm, repeatedPIN: pin)
        case .change, .verify:
            .ok
        }
    }

    private func setPINValidation(pin: String) -> FormTextInput.ValidationStatus {
        pin.count >= 4 ? .ok : .failure(L10n.PINLock.Error.tooShort)
    }

    private func confirmPINValidation(pin: String, repeatedPIN: String) -> FormTextInput.ValidationStatus {
        pin == repeatedPIN ? .ok : .failure(L10n.Settings.App.repeatedPINValidationError)
    }
}
