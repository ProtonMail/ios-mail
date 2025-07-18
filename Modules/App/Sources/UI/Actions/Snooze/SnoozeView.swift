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
import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct SnoozeView: View {
    @StateObject var store: SnoozeStore

    private static let gridSpacing = DS.Spacing.medium

    enum Screen: CaseIterable {
        case custom
        case main
    }

    init(snoozeActions: SnoozeActions, initialScreen: Screen = .main) {
        _store = .init(
            wrappedValue: .init(
                state: .initial(
                    actions: snoozeActions, screen: initialScreen)
            ))
    }

    private let columns = [
        GridItem(.flexible(), spacing: gridSpacing),
        GridItem(.flexible(), spacing: gridSpacing),
    ]

    var body: some View {
        sheetContent
            .animation(.easeInOut, value: store.state.screen)
            .transition(.identity)
            .presentationDetents(store.state.allowedDetents, selection: $store.state.currentDetent)
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
    }

    @ViewBuilder
    private var sheetContent: some View {
        switch store.state.screen {
        case .custom:
            DatePickerView(
                configuration: SnoozeDatePickerConfiguration(),
                onCancel: { store.handle(action: .customSnoozeCancelTapped) },
                onSelect: { _ in }
            )
        case .main:
            ClosableScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.medium) {
                        LazyVGrid(columns: columns, alignment: .center, spacing: Self.gridSpacing) {
                            ForEach(store.state.actions.predefined, id: \.self) { predefinedSnooze in
                                buttonWithIcon(for: predefinedSnooze)
                            }
                        }
                        switch store.state.actions.customButtonType {
                        case .regular:
                            customButton()
                        case .upgrade:
                            UpgradeButton()
                        }
                        if store.state.actions.isUnsnoozeVisible {
                            unsnoozeButton()
                                .padding(.top, DS.Spacing.medium)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.large)
                    .padding(.top, DS.Spacing.medium)
                    .padding(.bottom, DS.Spacing.extraLarge)
                }
                .navigationTitle(L10n.Snooze.snoozeUntil.string)
                .navigationBarTitleDisplayMode(.inline)
                .background(DS.Color.BackgroundInverted.norm)
            }
        }
    }

    private func buttonWithIcon(for model: PredefinedSnooze) -> some View {
        Button(action: { store.handle(action: .predefinedSnoozeOptionTapped(model)) }) {
            VStack(alignment: .center, spacing: DS.Spacing.standard) {
                Image(symbol: model.icon)
                    .font(.title2)
                    .foregroundStyle(DS.Color.Text.norm)
                VStack(alignment: .center, spacing: DS.Spacing.small) {
                    Text(model.title)
                        .font(.callout)
                        .foregroundStyle(DS.Color.Text.norm)
                    Text(model.time)
                        .font(.footnote)
                        .foregroundStyle(DS.Color.Text.weak)
                }
            }
            .padding(.vertical, DS.Spacing.moderatelyLarge)
            .padding(.horizontal, DS.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .center)
            .contentShape(Rectangle())
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .buttonStyle(DefaultPressedButtonStyle())
        .roundedRectangleStyle()
    }

    private func unsnoozeButton() -> some View {
        FormSmallButton(title: L10n.Snooze.unsnoozeButtonTitle, rightSymbol: nil) {
            store.handle(action: .unsnoozeTapped)
        }
        .roundedRectangleStyle()
    }

    private func customButton() -> some View {
        FormBigButton(
            title: L10n.Snooze.customButtonTitle,
            symbol: .chevronRight,
            value: L10n.Snooze.customButtonSubtitle.string
        ) {
            store.handle(action: .customButtonTapped)
        }
        .roundedRectangleStyle()
    }
}
