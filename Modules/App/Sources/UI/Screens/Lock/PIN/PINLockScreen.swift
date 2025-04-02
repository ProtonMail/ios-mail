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
    enum KeyboardButton: Hashable {
        case digit(_ value: Int)
        case delete

        var isDigit: Bool {
            switch self {
            case .digit:
                true
            case .delete:
                false
            }
        }
    }

    @StateObject var store: PINLockStateStore
    @Binding var error: String?

    init(
        pin: String = .empty,
        error: Binding<String?>,
        output: @escaping (PINLockScreenOutput) -> Void
    ) {
        self._store = .init(wrappedValue: .init(state: .init(pin: pin), output: output))
        self._error = error
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.Background.norm
                    .ignoresSafeArea(.all)

                VStack {
                    Image(systemName: DS.SFSymbols.lock)
                        .font(.title)
                        .padding(.vertical, DS.Spacing.large)
                    pinIndicator()
                        .frame(height: 20, alignment: .center)
                        .frame(maxWidth: 300)

                    Text(store.state.error ?? "")
                        .frame(height: 20)
                        .foregroundStyle(DS.Color.Notification.error)

                    Spacer()

                    VStack(alignment: .trailing, spacing: DS.Spacing.medium) {
                        ForEach(keyboard, id: \.self) { rowButtons in
                            HStack(spacing: DS.Spacing.large) {
                                ForEach(rowButtons, id: \.self) { button in
                                    Button(action: { store.handle(action: .keyboardTapped(button)) }) {
                                        visualElement(for: button)
                                            .font(.title)
                                            .foregroundStyle(DS.Color.Text.norm)
                                            .square(size: 92)
                                            .background(button.isDigit ? DS.Color.InteractionWeak.norm : .clear)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                    }

                    Spacer()

                    Button(
                        action: { store.handle(action: .confirmTapped) },
                        label: {
                            Text(L10n.Common.confirm)
                                .foregroundStyle(DS.Color.Text.inverted)
                        }
                    )
                    .buttonStyle(BigButtonStyle())
                    .padding(DS.Spacing.large)
                }
            }
            .navigationTitle(L10n.PINLock.screenTopTitle.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { store.handle(action: .signOutTapped) }) {
                        Image(systemName: DS.SFSymbols.rectanglePortraitAndArrowRight)
                            .foregroundStyle(DS.Color.Icon.norm)
                    }
                }
            }
            .onChange(of: error, { _, newValue in
                store.handle(action: .error(newValue))
            })
            .alert(model: $store.state.alert)
        }
    }

    @ViewBuilder
    private func visualElement(for button: KeyboardButton) -> some View {
        switch button {
        case .digit(let value):
            Text("\(value)".notLocalized)
        case .delete:
            Image(systemName: DS.SFSymbols.deleteLeft)
        }
    }

    @ViewBuilder
    func pinIndicator() -> some View {
        if store.state.pin.isEmpty {
            Text(L10n.PINLock.enterPinTitle)
                .foregroundStyle(DS.Color.Text.weak)
        } else {
            HStack(spacing: DS.Spacing.small) {
                ForEach(0..<store.state.pin.count, id: \.self) { _ in
                    Circle()
                        .fill(DS.Color.InteractionBrand.norm)
                        .square(size: 10)
                }
            }
        }
    }

    private var keyboard: [[KeyboardButton]] {
        [
            [.digit(1), .digit(2), .digit(3)],
            [.digit(4), .digit(5), .digit(6)],
            [.digit(7), .digit(8), .digit(9)],
            [.digit(0), .delete]
        ]
    }

}

