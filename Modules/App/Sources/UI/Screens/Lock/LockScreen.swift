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
import proton_app_uniffi

struct LockScreen: View {
    @StateObject var store: LockScreenStore

    init(state: LockScreenState, pinVerifier: PINVerifier, output: @escaping (LockScreenOutput) -> Void) {
        _store = .init(wrappedValue: .init(state: state, pinVerifier: pinVerifier, lockOutput: output))
    }

    var body: some View {
        switch store.state.type {
        case .pin:
            PINLockScreen(state: .init(hideLogoutButton: true, pin: .empty), error: pinErrorBinding) { output in
                store.handle(action: .pin(output))
            }.onLoad {
                store.handle(action: .pinScreenLoaded)
            }
        case .biometric:
            BiometricLockScreen { output in
                store.handle(action: .biometric(output))
            }
        }
    }

    private var pinErrorBinding: Binding<String?> {
        .init(
            get: { store.state.pinError },
            set: { _ in }
        )
    }

}
