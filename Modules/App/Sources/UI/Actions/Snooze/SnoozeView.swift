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
import SwiftUI

enum SnoozeViewAction {
    case transtion(to: SnoozeView.Screen)
}

struct SnoozeState: Copying {
    var screen: SnoozeView.Screen
    let actions: SnoozeActions
    var currentDetent: PresentationDetent
    var allowedDetents: Set<PresentationDetent>
}

extension SnoozeState {

    static func initial(actions: SnoozeActions) -> Self {
        let screen = SnoozeView.Screen.main
        return .init(screen: screen, actions: actions, currentDetent: screen.detent, allowedDetents: [screen.detent])
    }

}

class SnoozeStore: StateStore {
    @Published var state: SnoozeState

    init(state: SnoozeState) {
        self.state = state
    }

    @MainActor
    func handle(action: SnoozeViewAction) async {
        switch action {
        case .transtion(let screen):
            withAnimation {
                state = state
                    .copy(\.screen, to: screen)
                    .copy(\.allowedDetents, to: screen.allowedDetents)
                    .copy(\.currentDetent, to: screen.detent)
            } completion: { [weak self] in
                guard let self else { return }
                self.state = self.state
                    .copy(\.allowedDetents, to: [screen.detent])
            }
        }
    }
}

import InboxDesignSystem

import struct InboxComposer.ScheduleSendDateFormatter

struct SnoozeDatePickerConfiguration: DatePickerViewConfiguration {
    let title: LocalizedStringResource = "Snooze message"
    let selectTitle: LocalizedStringResource = "Save"
    var minuteInterval: TimeInterval = 30

    var range: ClosedRange<Date> {
        let start = Date()
        let end = Date.distantFuture
        return start...end
    }

    let formatter = ScheduleSendDateFormatter()

    func formatDate(_ date: Date) -> String {
        formatter.string(from: date, format: .medium)
    }
}

struct SnoozeView: View {
    @StateObject var store: SnoozeStore

    private static let gridSpacing = DS.Spacing.medium

    enum Screen: CaseIterable {
        case custom
        case main

        var detent: PresentationDetent {
            switch self {
            case .custom:
                .large
            case .main:
                .medium
            }
        }

        var allowedDetents: Set<PresentationDetent> {
            Set(Self.allCases.map(\.detent))
        }
    }

    init(snoozeActions: SnoozeActions) {
        _store = .init(wrappedValue: .init(state: .initial(actions: snoozeActions)))
    }

    private let columns = [
        GridItem(.flexible(), spacing: gridSpacing),
        GridItem(.flexible(), spacing: gridSpacing),
    ]

    @ViewBuilder
    var sheetContent: some View {
        Group {
            switch store.state.screen {
            case .custom:
                DatePickerView(
                    configuration: SnoozeDatePickerConfiguration(),
                    onCancel: { store.handle(action: .transtion(to: .main)) },
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
                                EmptyView()
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
                    .navigationTitle("Snooze until")
                    .navigationBarTitleDisplayMode(.inline)
                    .background(DS.Color.BackgroundInverted.norm)
                }
            }
        }
    }

    var body: some View {
        sheetContent
            .animation(.easeInOut, value: store.state.screen)
            .transition(.identity)
            .presentationDetents(store.state.allowedDetents, selection: $store.state.currentDetent)
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
    }

    private func buttonWithIcon(for model: PredefinedSnooze) -> some View {
        Button(action: {}) {
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
        FormSmallButton(title: "Unsnooze", rightSymbol: nil) {
            print("Unsnooze")
        }
        .roundedRectangleStyle()
    }

    private func customButton() -> some View {
        FormBigButton(
            title: "Custom",
            symbol: .chevronRight,
            value: "Pick time and date"
        ) {
            store.handle(action: .transtion(to: .custom))
        }
            .roundedRectangleStyle()
    }
}

extension PredefinedSnooze {

    var title: String {
        switch type {
        case .tomorrow:
            "Tomorrow"
        case .laterThisWeek:
            "Later this week"
        case .nextWeek:
            "Next week"
        case .thisWeekend:
            "This weekend"
        }
    }

    var icon: DS.SFSymbol {
        switch type {
        case .tomorrow:
            .sunMax
        case .laterThisWeek:
            .sunLeftHalfFilled
        case .thisWeekend:
            .sofa
        case .nextWeek:
            .suitcase
        }
    }

    var time: String {
        let formatter =
            switch type {
            case .tomorrow:
                SnoozeFormatter.timeOnlyFormatter
            case .laterThisWeek, .thisWeekend, .nextWeek:
                SnoozeFormatter.weekDayWithTimeFormatter
            }
        return formatter.string(from: date)
    }

}

private enum SnoozeFormatter {
    static let timeOnlyFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("jm")
        return formatter
    }()

    static let weekDayWithTimeFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEjm")
        return formatter
    }()
}

// MARK: - Rust API

import Foundation

struct SnoozeActions {
    let predefined: [PredefinedSnooze]
    let isUnsnoozeVisible: Bool
    let customButtonType: CustomButtonType

    enum CustomButtonType {
        case regular
        case upgrade
    }
}

struct PredefinedSnooze: Hashable {
    let type: PredefinedSnoozeType
    let date: Date

    enum PredefinedSnoozeType: Hashable {
        case tomorrow
        case laterThisWeek
        case thisWeekend
        case nextWeek
    }
}

//#Preview {
//    SnoozeView(snoozeActions: .init(
//        predefined: [
//            .init(type: .tomorrow, date: Date()),
//            .init(type: .laterThisWeek, date: Date()),
//            .init(type: .thisWeekend, date: Date()),
//            .init(type: .nextWeek, date: Date())
//        ],
//        isUnsnoozeVisible: true,
//        customButtonType: .regular
//    ))
//}
