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
import InboxCore
import InboxCoreUI

struct EditToolbarState: Copying {
    let toolbarActions: ToolbarActions
}

extension EditToolbarState {

    static func initial(toolbarActions: ToolbarActions) -> Self {
        .init(toolbarActions: toolbarActions)
    }

}

enum EditToolbarAction {
//    case selectedActionReordered(fromIndex: Int, toIndex: Int)
//    case removeFromSelectedActions(index: Int)
}

@MainActor
class EditToolbarStore: StateStore {
    @Published var state: EditToolbarState

    init(state: EditToolbarState) {
        self.state = state
    }

    func handle(action: EditToolbarAction) async {

    }
}

import InboxDesignSystem

struct EditToolbarScreen: View {
    @StateObject var store: EditToolbarStore

    init(state: EditToolbarState) {
        self._store = .init(wrappedValue: .init(state: state))
    }

    var body: some View {
        List {
            chosenActionsSection()
            availableActionsSection()
                .moveDisabled(true)
            resetToOriginalSection()
        }
        .listSectionSpacing(DS.Spacing.extraLarge)
        .navigationTitle("Edit list toolbar")
        .environment(\.editMode, .constant(.active))
    }

    private func chosenActionsSection() -> some View {
        Section {
            ForEach(store.state.toolbarActions.selected) { action in
                HStack(spacing: DS.Spacing.medium) {
                    Button(action: {
                        print("*** MINUS ACTION")
                    }) {
                        Image(symbol: .minusCircleFill)
                            .foregroundStyle(DS.Color.Notification.error)
                            .frame(width: 24, height: 24, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    action.displayData.image
                        .resizable()
                        .square(size: 20)
                        .foregroundStyle(DS.Color.Icon.norm)

                    Text(action.displayData.title)
                        .foregroundStyle(DS.Color.Text.norm)
                }
                .selectionDisabled()
            }
            .onMove { position, destination in
                print("*** FROM: \(position) TO: \(destination)")
            }
        } header: {
            VStack(alignment: .leading, spacing: DS.Spacing.mediumLight) {
                Text("Chosen actions")
                    .foregroundStyle(DS.Color.Text.norm)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text("The toolbar can have 1–5 actions. You can’t remove the last remaining action.")
                    .foregroundStyle(DS.Color.Text.weak)
                    .font(.footnote)
            }
            .padding(.bottom, DS.Spacing.small)
        }
        .textCase(.none)
    }

    private func availableActionsSection() -> some View {
        Section {
            ForEach(store.state.toolbarActions.unselected) { action in
                HStack(spacing: DS.Spacing.medium) {
                    Button(action: {
                        print("*** MINUS ACTION")
                    }) {
                        Image(symbol: .plusCircleFill)
                            .foregroundStyle(DS.Color.Notification.success)
                            .frame(width: 24, height: 24, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    action.displayData.image
                        .resizable()
                        .square(size: 20)
                        .foregroundStyle(DS.Color.Icon.norm)

                    Text(action.displayData.title)
                        .foregroundStyle(DS.Color.Text.norm)
                }
                .selectionDisabled()
            }
        } header: {
            Text("Available actions")
                .foregroundStyle(DS.Color.Text.norm)
                .font(.callout)
                .fontWeight(.semibold)
                .padding(.bottom, DS.Spacing.small)
        }
        .textCase(.none)
    }

    private func resetToOriginalSection() -> some View {
        Section {
            Button(action: { print("*** RESET TO ORIGINAL TAP") }) {
                HStack {
                    Text("Reset to original")
                    Spacer()
                    Image(symbol: .arrowClockwise)
                }
                .foregroundStyle(DS.Color.Text.accent)
            }
        } footer: {
            Text("Restores the toolbar actions for the message view to their original default settings.")
                .foregroundStyle(DS.Color.Text.weak)
                .font(.footnote)
                .padding(.top, DS.Spacing.small)
        }
        .textCase(.none)
    }

}

extension ToolbarActionType: Identifiable {
    var id: String {
        displayData.title.string
    }
}

#Preview {
    EditToolbarScreen(
        state: .initial(
            toolbarActions: .init(
                selected: [.markAsUnread, .archive, .labelAs],
                unselected: [.moveTo, .moveToSpam, .moveToTrash, .snooze, .star]
            )
        ))
}
