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

import InboxCoreUI
import SwiftUI

enum SnoozeViewAction {
    case customButtonTapped
}

struct SnoozeState {
    let actions: SnoozeActions
    var customOptionsPresented: Bool
}

extension SnoozeState {

    static func initial(actions: SnoozeActions) -> Self {
        .init(actions: actions, customOptionsPresented: false)
    }

}

class SnoozeStore: StateStore {
    @Published var state: SnoozeState

    init(state: SnoozeState) {
        self.state = state
    }

    func handle(action: SnoozeViewAction) async {

    }
}

import InboxDesignSystem

struct SnoozeView: View {
    @StateObject var store: SnoozeStore

    init(snoozeActions: SnoozeActions) {
        _store = .init(wrappedValue: .init(state: .initial(actions: snoozeActions)))
    }

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.medium) {
                    ForEach(store.state.actions.predefined, id: \.self) { predefinedSnooze in
                        buttonWithIcon(for: predefinedSnooze)
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
                .padding(.bottom, DS.Spacing.extraLarge)
            }
            .sheet(isPresented: $store.state.customOptionsPresented) {
                SnoozeCustomOptionsView()
                    .presentationDetents([.medium, .large])
            }
            .background(DS.Color.BackgroundInverted.norm)
            .navigationTitle("Snooze until")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func buttonWithIcon(for model: PredefinedSnooze) -> some View {
        Button(action: {}) {
            HStack(alignment: .center, spacing: DS.Spacing.moderatelyLarge) {
                Image(symbol: model.icon)
                    .font(.title2)
                    .foregroundStyle(DS.Color.Text.norm)
                VStack(alignment: .leading, spacing: DS.Spacing.small) {
                    Text(model.title)
                        .font(.callout)
                        .foregroundStyle(DS.Color.Text.norm)
                    Text(model.time)
                        .foregroundStyle(DS.Color.Text.weak)
                }
            }
            .padding(.vertical, DS.Spacing.moderatelyLarge)
            .padding(.horizontal, DS.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
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
            store.state.customOptionsPresented.toggle()
            print("Custom button")
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
            .suitcase // FIXME: - To update
        case .nextWeek:
            .suitcase
        }
    }

    var time: String {
        let formatter = switch type {
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

struct SnoozeCustomOptionsView: View {
    @State var date: Date = Date.now

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.large) {
                    DatePicker(selection: $date, displayedComponents: .hourAndMinute) {
                        Text("Time")
                    }
                    .padding(.horizontal, DS.Spacing.large)
                    .padding(.vertical, DS.Spacing.moderatelyLarge)
                    .background(DS.Color.BackgroundInverted.secondary)
                    .roundedRectangleStyle()

                    DatePicker(selection: $date, displayedComponents: .date) {
                        Text("Date")
                    }
                    .padding(.horizontal, DS.Spacing.large)
                    .padding(.vertical, DS.Spacing.moderatelyLarge)
                    .background(DS.Color.BackgroundInverted.secondary)
                    .roundedRectangleStyle()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DS.Spacing.large)
                .padding(.vertical, DS.Spacing.standard)
            }
            .background(DS.Color.BackgroundInverted.norm)
            .navigationTitle("Snooze message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Text("Save") // FIXME: - Reuse it
                            .fontWeight(.semibold)
                            .foregroundStyle(DS.Color.InteractionBrand.norm)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {}) {
                        Text("Cancel")
                            .foregroundStyle(DS.Color.InteractionBrand.norm)
                    }
                }
            }
        }
    }

}

#Preview {
    SnoozeCustomOptionsView()
}
