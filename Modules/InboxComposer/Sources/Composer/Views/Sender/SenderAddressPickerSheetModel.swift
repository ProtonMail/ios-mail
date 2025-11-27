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
import ProtonUIFoundations
import SwiftUI

@MainActor
final class SenderAddressPickerSheetModel: ObservableObject {
    @Published var state: SenderAddressPickerSheetState
    private let handler: ChangeSenderHandlerProtocol
    private let toastStateStore: ToastStateStore
    private let dismiss: () -> Void

    init(
        state: SenderAddressPickerSheetState,
        handler: ChangeSenderHandlerProtocol,
        toastStateStore: ToastStateStore,
        dismiss: @escaping () -> Void
    ) {
        self.state = state
        self.handler = handler
        self.toastStateStore = toastStateStore
        self.dismiss = dismiss
    }

    func handleAction(_ action: SenderAddressPickerSheetAction) async {
        do {
            switch action {
            case .viewAppear:
                let addresses = try await handler.listSenderAddresses()
                state = state.copy(\.addresses, to: addresses.available)
                    .copy(\.activeAddress, to: addresses.active)
            case .selected(let address):
                guard address != state.activeAddress else { return }
                state = state.copy(\.activeAddress, to: address)
                try await handler.changeSenderAddress(email: address)
                dismiss()
            }
        } catch {
            toastStateStore.present(toast: .error(message: error.localizedDescription))
            dismiss()
        }
    }
}

enum SenderAddressPickerSheetAction {
    case viewAppear
    case selected(String)
}

struct SenderAddressPickerSheetState: Equatable, Copying {
    var addresses: [String] = []
    var activeAddress: String = ""
}
