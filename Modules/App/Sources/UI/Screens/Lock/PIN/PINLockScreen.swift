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
import InboxCoreUI
import InboxDesignSystem
import InboxCore

struct PINLockScreen: View {
    @StateObject var store: PINLockStateStore
    @Binding var error: PINAuthenticationError?
    @FocusState var isFocused: Bool

    init(
        state: PINLockState,
        error: Binding<PINAuthenticationError?>,
        output: @escaping (PINLockScreenOutput) -> Void
    ) {
        self._store = .init(wrappedValue: .init(state: state, output: output))
        self._error = error
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                BlurredCoverView(showLogo: false)
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Text(L10n.PINLock.signOut)
                            .foregroundStyle(DS.Color.Text.norm)
                    }
                    .padding(.trailing, DS.Spacing.large)
                }
                VStack(alignment: .center, spacing: .zero) {
                    Image(DS.Images.protonMail)
                        .resizable()
                        .square(size: 90)
                        .padding(.top, geometry.size.height * 0.20)
                        .shadow(Shadow(x: 0, y: 0, blur: 8, color: DS.Color.Global.black.opacity(0.06)), isVisible: true)
                        .shadow(Shadow(x: 0, y: 0, blur: 50, color: DS.Color.Global.black.opacity(0.10)), isVisible: true)
                    Text(L10n.PINLock.title)
                        .foregroundStyle(DS.Color.Text.norm)
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.top, DS.Spacing.huge)
                        .padding(.bottom, DS.Spacing.standard)

                    subtitle
                        .transition(.opacity)

                    SecureField(L10n.PINLock.pinInputPlaceholder.string, text: pinBinding)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .tint(DS.Color.Text.accent)
                        .focused($isFocused)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .padding(.top, DS.Spacing.huge)

                    Spacer()
                    confirmButton
                        .padding(.horizontal, DS.Spacing.extraLarge)
                        .padding(.bottom, DS.Spacing.extraLarge)
                }
            }
            .onAppear {
                isFocused = true
            }
            .onChange(of: isFocused) { _, _ in isFocused = true }
            .onChange(of: error) { _, description in
                if let description {
                    store.handle(action: .error(description))
                }
            }
            .onChange(of: store.state.error) { _, newValue in
                error = newValue
            }
        }
    }

    @ViewBuilder
    private var subtitle: some View {
        if let error = store.state.error?.humanReadable {
            Text(error)
                .foregroundStyle(DS.Color.Notification.error)
        } else {
            Text(L10n.PINLock.subtitle)
                .font(.callout)
                .foregroundStyle(DS.Color.Text.weak)
        }
    }

    private var pinBinding: Binding<String> {
        .init(
            get: { store.state.pin.toString },
            set: { newValue in store.handle(action: .pinEntered(newValue.digits)) }
        )
    }

    private var confirmButton: some View {
        Button(
            action: { store.handle(action: .confirmTapped) },
            label: { Text(CommonL10n.confirm) }
        )
        .buttonStyle(BigButtonStyle())
    }

}

#Preview {
    PINLockScreen(
        state: .init(hideLogoutButton: false, pin: []),
        error: .readonly(get: { nil }),
        output: { _ in }
    )
}
