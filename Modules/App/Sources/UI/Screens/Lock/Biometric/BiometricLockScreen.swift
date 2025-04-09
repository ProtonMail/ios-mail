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

struct BiometricLockScreen: View {
    @StateObject var store: BiometricLockStore

    init(state: BiometricLockState = .initial, output: @escaping (BiometricLockScreenOutput) -> Void) {
        _store = .init(wrappedValue: .init(state: state, output: output))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                DS.Color.Background.norm
                    .ignoresSafeArea(.all)
                Image(DS.Images.protonMail)
                    .square(size: 120)
                    .padding(.top, geometry.size.height * 0.37)
                    .shadow(Shadow(x: 0, y: 0, blur: 8, color: DS.Color.Global.black.opacity(0.06)), isVisible: true)
                    .shadow(Shadow(x: 0, y: 0, blur: 50, color: DS.Color.Global.black.opacity(0.10)), isVisible: true)
                if store.state.displayUnlockButton {
                    VStack {
                        Spacer()
                        Button(action: { store.handle(action: .unlockTapped) }) {
                            Text("Unlock Proton Mail")
                                .foregroundStyle(DS.Color.Text.norm)
                                .padding(.vertical, DS.Spacing.medium)
                                .frame(maxWidth: .infinity)
                                .background(DS.Color.InteractionWeak.norm)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, DS.Spacing.extraLarge)
                        .padding(.bottom, DS.Spacing.extraLarge)
                    }
                }
            }
        }
        .onLoad {
            store.handle(action: .onLoad)
        }
    }

}

#Preview {
    BiometricLockScreen(output: { _ in })
}
