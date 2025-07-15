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

import InboxDesignSystem
import SwiftUI

public struct BiometricLockScreen: View {
    @StateObject var store: BiometricLockStore

    init(
        state: BiometricLockState = .initial,
        authenticationMethod: BiometricAuthenticator.AuthenticationMethod = .builtIn { .init() },
        output: @escaping (BiometricLockScreenOutput) -> Void
    ) {
        _store = .init(wrappedValue: .init(state: state, method: authenticationMethod, output: output))
    }

    public init(authenticationMethod: BiometricAuthenticator.AuthenticationMethod) {
        self.init(state: .initial, authenticationMethod: authenticationMethod, output: { _ in })
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                BlurredCoverView(showLogo: true)
                if store.state.displayUnlockButton {
                    VStack {
                        Spacer()
                        Button(action: { store.handle(action: .unlockTapped) }) {
                            Text(L10n.BiometricLock.unlockButtonTitle)
                                .foregroundStyle(DS.Color.Text.inverted)
                                .padding(.vertical, DS.Spacing.medium)
                                .frame(maxWidth: .infinity)
                                .background(DS.Color.InteractionBrand.norm)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, DS.Spacing.extraLarge)
                        .padding(.bottom, DS.Spacing.extraLarge)
                    }
                }
            }
        }
        .alert(model: $store.state.alert)
        .onLoad {
            store.handle(action: .onLoad)
        }
    }

}

#Preview {
    BiometricLockScreen(output: { _ in })
}
