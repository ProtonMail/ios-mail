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

import SwiftUI
import InboxCore

import proton_app_uniffi

protocol AppProtectionConfigurator: Sendable {
    func deletePinCode(pin: [UInt32]) async -> MailSessionDeletePinCodeResult
    func setPinCode(pin: [UInt32]) async -> MailSessionSetPinCodeResult
    func setBiometricsAppProtection() async -> MailSessionSetBiometricsAppProtectionResult
    func verifyPinCode(pin: [UInt32]) async -> MailSessionVerifyPinCodeResult
    func unsetBiometricsAppProtection() async -> MailSessionUnsetBiometricsAppProtectionResult
}

extension PinAuthError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .reason(let errorReason):
            switch errorReason {
            case .incorrectPin:
                "Incorrect PIN" // FIXME: - Check text
            case .tooManyAttempts:
                "Too many attemts" // FIXME: - Check text
            case .tooFrequentAttempts:
                "Too frequent attempts" // FIXME: - Check text
            }
        case .other(let protonError):
            protonError.localizedDescription
        }
    }

}

extension MailSession: AppProtectionConfigurator {}

class PINStateStore: StateStore {
    @Published var state: PINScreenState
    private let pinScreenValidator: PINValidator
    private let router: Router<PINRoute>
    private let appProtectionConfigurator: AppProtectionConfigurator
    private let biometricAuthenticator: BiometricAuthenticator
    private let dismiss: () -> Void

    init(
        state: PINScreenState,
        router: Router<PINRoute>,
        pinVerifier: PINVerifier,
        appProtectionConfigurator: AppProtectionConfigurator,
        laContext: @Sendable @escaping () -> LAContext = { LAContext() },
        dismiss: @escaping () -> Void
    ) {
        self.state = state
        self.pinScreenValidator = .init(pinScreenType: state.type, pinVerifier: pinVerifier)
        self.router = router
        self.appProtectionConfigurator = appProtectionConfigurator
        self.biometricAuthenticator = .init(method: .builtIn(laContext))
        self.dismiss = dismiss
    }

    @MainActor
    func handle(action: PINScreenAction) async {
        switch action {
        case .pinTyped(let pin):
            state = state.copy(\.pin, to: pin)
                .copy(\.pinValidation, to: .ok)
        case .leadingButtonTapped:
            if router.stack.isEmpty {
                dismiss()
            } else {
                router.goBack()
            }
        case .trailingButtonTapped:
            let pinValidationResult = await pinScreenValidator.validate(pin: state.pin)
            state = state.copy(\.pinValidation, to: pinValidationResult)
            guard pinValidationResult.isSuccess else {
                return
            }
            switch state.type {
            case .set:
                router.go(to: .pin(type: .confirm(pin: state.pin)))
            case .confirm(let pin):
                await confirm(pin: pin)
            case .verify(let reason):
                await verifyPIN(reason: reason)
            }
        }
    }

    @MainActor
    private func confirm(pin: String) async {
        do {
            try await appProtectionConfigurator.setPinCode(pin: pin.digits).get()
        } catch {
            AppLogger.log(error: error, category: .appSettings)
        }
        dismiss()
    }

    @MainActor
    private func verifyPIN(reason: PINVerificationReason) async {
        switch reason {
        case .changePIN:
            router.go(to: .pin(type: .set))
        case .disablePIN:
            do {
                try await appProtectionConfigurator.deletePinCode(pin: state.pin.digits).get()
                dismiss()
            } catch {
                state = state.copy(\.pinValidation, to: .failure(error.localizedDescription))
            }
        case .changeToBiometry:
            do {
                try await appProtectionConfigurator.deletePinCode(pin: state.pin.digits).get()
                await setUpBioemtryProtection()
            } catch {
                state = state.copy(\.pinValidation, to: .failure(error.localizedDescription))
            }
        }
    }

    @MainActor
    private func setUpBioemtryProtection() async {
        guard await biometricAuthenticator.authenticate().isSuccess else {
            dismiss()
            return
        }
        do {
            try await appProtectionConfigurator.setBiometricsAppProtection().get()
        } catch {
            AppLogger.log(error: error)
        }
        dismiss()
    }
}

import LocalAuthentication

extension String {

    var digits: [UInt32] {
        compactMap { UInt32(String($0)) }
    }

}
extension BiometricAuthenticator.AuthenticationStatus {
    var isSuccess: Bool {
        switch self {
        case .success:
            true
        case .failure:
            false
        }
    }
}
