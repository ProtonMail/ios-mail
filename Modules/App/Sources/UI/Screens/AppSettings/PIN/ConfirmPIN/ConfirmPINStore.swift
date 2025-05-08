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
import InboxDesignSystem

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
        case .confirm(let repeatedPIN):
            confirmPINValidation(pin: pin, repeatedPIN: repeatedPIN)
        case .verify:
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

struct PINActionPerformer {
    enum Action {
        case changePIN(old: String, new: String)
        case verify(pin: String)
    }

    func perform(action: Action) async {
        switch action {
        case .changePIN(let old, let new):
            // FIXME: - Call Rust to change PIN
        case .verify(let pin):
            // FIXME: - Call Rust to verify PIN
        }
    }
}

enum PINScreenType: Hashable {
    case set
    case confirm(pin: String)
    case verify

    var pinInputTitle: LocalizedStringResource {
        switch self {
        case .set:
            L10n.Settings.App.setPINInputTitle
        case .confirm:
            L10n.Settings.App.repeatPIN
        case .verify:
            ""
        }
    }

    var screenTitle: LocalizedStringResource {
        switch self {
        case .set:
            L10n.Settings.App.setPINScreenTitle
        case .confirm:
            L10n.Settings.App.repeatPIN
        case .verify:
            ""
        }
    }

    var trailingButtonTitle: LocalizedStringResource {
        switch self {
        case .set:
            L10n.Common.next
        case .confirm:
            L10n.Common.confirm
        case .verify:
            ""
        }
    }

}

struct PINScreenState: Copying {
    var pin: String
    var pinValidation: FormTextInput.ValidationStatus
    var pinInputTitle: LocalizedStringResource
    var trailingButtonTitle: LocalizedStringResource
    var screenTitle: LocalizedStringResource
}

extension PINScreenState {
    static func initial(type: PINScreenType) -> Self {
        .init(
            pin: .empty,
            pinValidation: .ok,
            pinInputTitle: type.pinInputTitle,
            trailingButtonTitle: type.trailingButtonTitle,
            screenTitle: type.screenTitle
        )
    }
}

enum PINScreenAction {
    case pinTyped(String)
    case trailingButtonTapped
}

enum PINScreenCompletion: Hashable {
    case entered(pin: String)
    case confirmed(pin: String, repeatedPIN: String)
    case verified
}

class PINStateStore: StateStore {
    @Published var state: PINScreenState
    private let pinScreenValidator: PINValidator
    private let type: PINScreenType

    init(state: PINScreenState, type: PINScreenType) {
        self.state = state
        self.type = type
        self.pinScreenValidator = .init(pinScreenType: type)
    }

    @MainActor
    func handle(action: PINScreenAction) async {
        switch action {
        case .pinTyped(let pin):
            state = state.copy(\.pin, to: pin)
                .copy(\.pinValidation, to: .ok)
        case .trailingButtonTapped:
            state = state.copy(\.pinValidation, to: pinScreenValidator.validate(pin: state.pin))
            if state.pinValidation.isSuccess {
                switch type {
                case .set:

                case .confirm(let pin):

                case .verify:

                }
            }
        }
    }
}

struct PINScreen: View {
    @StateObject var store: PINStateStore

    init(type: PINScreenType) {
        self._store = .init(wrappedValue: .init(state: .initial(type: type), type: type))
    }

    var body: some View {
        EnterPINView(
            title: L10n.Settings.App.repeatPIN,
            text: pin,
            validation: $store.state.pinValidation
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { store.handle(action: .trailingButtonTapped) }) {
                    Text(L10n.Common.confirm)
                        .fontWeight(.bold)
                        .foregroundStyle(DS.Color.Text.accent)
                }
            }
        }
        .navigationTitle(L10n.Settings.App.repeatPIN.string)
    }

    private var pin: Binding<String> {
        .init(
            get: { store.state.pin },
            set: { pin in store.handle(action: .pinTyped(pin)) }
        )
    }

}

class ConfirmPINStore: StateStore {
    @Published var state: ConfirmPINState
    private let router: Router<SettingsRoute>

    init(state: ConfirmPINState, router: Router<SettingsRoute>) {
        self.state = state
        self.router = router
    }

    @MainActor
    func handle(action: ConfirmPINAction) async {
        switch action {
        case .pinTyped(let repeatedPIN):
            state = state.copy(\.repeatedPIN, to: repeatedPIN)
                .copy(\.repeatedPINValidation, to: .ok)
        case .confirmButtonTapped:
            let doesPINMatch = state.pin == state.repeatedPIN
            state = state.copy(
                \.repeatedPINValidation,
                to: doesPINMatch ? .ok : .failure(L10n.Settings.App.repeatedPINValidationError)
            )
            if doesPINMatch {
                router.goBack(to: .appProtection)
            }
        }
    }
}
