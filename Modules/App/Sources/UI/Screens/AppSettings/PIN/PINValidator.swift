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
    private let pinVerifier: PINVerifier

    init(pinScreenType: PINScreenType, pinVerifier: PINVerifier) {
        self.pinScreenType = pinScreenType
        self.pinVerifier = pinVerifier
    }

    func validate(pin: PIN) async -> FormTextInput.ValidationStatus {
        switch pinScreenType {
        case .set:
            return setPINValidation(pin: pin)
        case .confirm(let newPIN, _):
            return confirmPINValidation(pin: newPIN, repeatedPIN: pin)
        case .verify(let reason):
            switch reason {
            case .changePIN:
                do {
                    try await pinVerifier.verifyPinCode(pin: pin.digits).get()
                    return .ok
                } catch {
                    return .failure(error.localizedDescription)
                }
            case .disablePIN, .changeToBiometry:
                return .ok
            }
        }
    }

    // FIXME: - This validation logic will be moved to Rust
    private func setPINValidation(pin: PIN) -> FormTextInput.ValidationStatus {
        switch pin.digits.count {
        case ..<4:
            .failure(L10n.PINLock.Error.tooShort.string)
        case 22...:
            .failure(L10n.PINLock.Error.tooLong.string)
        default:
            .ok
        }
    }

    // FIXME: - This validation logic will be moved to Rust
    private func confirmPINValidation(pin: PIN, repeatedPIN: PIN) -> FormTextInput.ValidationStatus {
        pin == repeatedPIN ? .ok : .failure(L10n.Settings.App.repeatedPINValidationError.string)
    }
}
