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

    init(state: SnoozeState) {
        _store = .init(wrappedValue: .init(state: state))
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
                            ForEach(store.state.options, id: \.self) { snoozeOption in
                                buttonWithIcon(for: snoozeOption)
                            }

                            if displayButtonOnGrid {
                                lastButton(displayOnGrid: true)
                            }
                        }

                        if !displayButtonOnGrid {
                            lastButton(displayOnGrid: false)
                        }

                        if store.state.showUnsnooze {
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

    @ViewBuilder
    private func lastButton(displayOnGrid: Bool) -> some View {
        let displayCustomButton = store.state.options.contains(.custom)
        if displayCustomButton {
            customButton(displayOnGrid: displayOnGrid)
        } else {
            SnoozeUpgradeButton(variant: displayOnGrid ? .compact : .fullLine) {
                store.handle(action: .upgradeTapped)
            }
        }
    }

    private var displayButtonOnGrid: Bool {
        store.state.options.count % 2 == 1
    }

    @ViewBuilder
    private func buttonWithIcon(for model: SnoozeTime) -> some View {
        gridButton(title: model.title, subtitle: model.subtitle, icon: model.icon) {
            store.handle(action: .predefinedSnoozeOptionTapped(model))
        }
    }

    private func unsnoozeButton() -> some View {
        Button(action: { store.handle(action: .unsnoozeTapped) }) {
            Text(L10n.Snooze.unsnoozeButtonTitle)
                .foregroundStyle(DS.Color.Text.norm)
                .font(.callout)
                .frame(maxWidth: .infinity, minHeight: 49, alignment: .center)
                .background(DS.Color.BackgroundInverted.secondary)
        }
        .roundedRectangleStyle()
    }

    @ViewBuilder
    private func gridButton(
        title: LocalizedStringResource,
        subtitle: String,
        icon: Image,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: DS.Spacing.standard) {
                icon
                    .font(.title2)
                    .foregroundStyle(DS.Color.Text.norm)
                VStack(alignment: .center, spacing: DS.Spacing.small) {
                    Text(title)
                        .font(.callout)
                        .foregroundStyle(DS.Color.Text.norm)
                    Text(subtitle)
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

    @ViewBuilder
    private func customButton(displayOnGrid: Bool) -> some View {
        let action = { store.handle(action: .customButtonTapped) }
        let title = L10n.Snooze.customButtonTitle
        let subtitle = L10n.Snooze.customButtonSubtitle.string
        if displayOnGrid {
            gridButton(title: title, subtitle: subtitle, icon: Image(DS.Icon.icCalendarToday), action: action)
        } else {
            FormBigButton(title: title, symbol: .chevronRight, value: subtitle, action: action)
                .roundedRectangleStyle()
        }
    }
}
