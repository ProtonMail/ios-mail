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
import InboxDesignSystem
import proton_app_uniffi

struct EditToolbarScreen: View {
    private let state: EditToolbarState
    private let customizeToolbarService: CustomizeToolbarServiceProtocol
    @Environment(\.dismiss) var dismiss
    @Environment(\.refreshToolbar) var refreshToolbarNotifier

    init(state: EditToolbarState, customizeToolbarService: CustomizeToolbarServiceProtocol) {
        self.state = state
        self.customizeToolbarService = customizeToolbarService
    }

    var body: some View {
        NavigationStack {
            StoreView(
                store: EditToolbarStore(
                    state: state,
                    customizeToolbarService: customizeToolbarService,
                    refreshToolbarNotifier: refreshToolbarNotifier,
                    dismiss: { dismiss.callAsFunction() }
                )
            ) { state, store in
                List {
                    chosenActionsSection(state: state, store: store)
                        .listRowBackground(DS.Color.BackgroundInverted.secondary)
                    availableActionsSection(state: state, store: store)
                        .listRowBackground(DS.Color.BackgroundInverted.secondary)
                        .moveDisabled(true)
                    resetToOriginalSection(store: store)
                        .listRowBackground(DS.Color.BackgroundInverted.secondary)
                }
                .background(DS.Color.BackgroundInverted.norm)
                .scrollContentBackground(.hidden)
                .listSectionSpacing(DS.Spacing.extraLarge)
                .navigationTitle(store.state.toolbarType.screenTitle.string)
                .navigationBarTitleDisplayMode(.inline)
                .environment(\.editMode, .constant(.active))
                .id(store.state.toolbarActions.unselected)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            store.handle(action: .saveTapped)
                        }) {
                            Text(CommonL10n.save)
                                .fontWeight(.semibold)
                                .foregroundStyle(DS.Color.Text.accent)
                        }
                    }

                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            store.handle(action: .cancelTapped)
                        }) {
                            Text(CommonL10n.cancel)
                                .foregroundStyle(DS.Color.Text.accent)
                        }
                    }
                }
                .onLoad {
                    store.handle(action: .onLoad)
                }
            }
        }
    }

    private func chosenActionsSection(state: EditToolbarState, store: EditToolbarStore) -> some View {
        Section {
            ForEach(state.toolbarActions.selected) { action in
                HStack(spacing: DS.Spacing.medium) {
                    Button(action: { store.handle(action: .removeFromSelectedTapped(actionToRemove: action)) }) {
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
                .disabled(state.selectedActionsListDisabled)
            }
            .onMove { fromOffsets, toOffset in
                store.handle(action: .actionsReordered(fromOffsets: fromOffsets, toOffset: toOffset))
            }
        } header: {
            VStack(alignment: .leading, spacing: DS.Spacing.mediumLight) {
                Text(L10n.Settings.CustomizeToolbars.chosenActionsSectionTitle)
                    .foregroundStyle(DS.Color.Text.norm)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(L10n.Settings.CustomizeToolbars.chosenActionsSectionSubtitle)
                    .foregroundStyle(DS.Color.Text.weak)
                    .font(.footnote)
            }
            .padding(.bottom, DS.Spacing.small)
        }
        .textCase(.none)
    }

    private func availableActionsSection(state: EditToolbarState, store: EditToolbarStore) -> some View {
        Section {
            ForEach(state.toolbarActions.unselected) { action in
                HStack(spacing: DS.Spacing.medium) {
                    Button(action: { store.handle(action: .addToSelectedTapped(actionToAdd: action)) }) {
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
                .disabled(state.availableActionsListDisabled)
            }
        } header: {
            Text(L10n.Settings.CustomizeToolbars.availableActionsSectionTitle)
                .foregroundStyle(DS.Color.Text.norm)
                .font(.callout)
                .fontWeight(.semibold)
                .padding(.bottom, DS.Spacing.small)
        }
        .textCase(.none)
    }

    private func resetToOriginalSection(store: EditToolbarStore) -> some View {
        Section {
            Button(action: { store.handle(action: .resetToOriginalTapped) }) {
                HStack {
                    Text(L10n.Settings.CustomizeToolbars.resetButtonTitle)
                    Spacer()
                    Image(symbol: .arrowClockwise)
                }
                .foregroundStyle(DS.Color.Text.accent)
            }
        } footer: {
            Text(L10n.Settings.CustomizeToolbars.resetButtonFooter)
                .foregroundStyle(DS.Color.Text.weak)
                .font(.footnote)
                .padding(.top, DS.Spacing.small)
        }
        .textCase(.none)
    }

}

private extension EditToolbarState {

    var availableActionsListDisabled: Bool {
        toolbarActions.selected.count >= 5
    }

    var selectedActionsListDisabled: Bool {
        toolbarActions.selected.count <= 1
    }

}

private extension ToolbarType {

    var screenTitle: LocalizedStringResource {
        switch self {
        case .list:
            L10n.Settings.CustomizeToolbars.listToolbarEditionScreenTitle
        case .message:
            L10n.Settings.CustomizeToolbars.messageToolbarEditionScreenTitle
        case .conversation:
            L10n.Settings.CustomizeToolbars.conversationToolbarSectionTitle
        }
    }

}

#if DEBUG
    #Preview {
        NavigationStack {
            EditToolbarScreen(
                state: .init(
                    toolbarType: .list,
                    toolbarActions: .init(
                        selected: [.toggleRead, .archive, .label],
                        unselected: [.move, .spam, .trash, .snooze, .toggleStar]
                    ),
                ),
                customizeToolbarService: CustomizeToolbarServiceStub()
            )
        }
    }

    private final class CustomizeToolbarServiceStub: CustomizeToolbarServiceProtocol {
        func getListToolbarActions() async throws(ActionError) -> [MobileAction] { [] }
        func getMessageToolbarActions() async throws(ActionError) -> [MobileAction] { [] }
        func getConversationToolbarActions() async throws(ActionError) -> [MobileAction] { [] }
        func updateListToolbarActions(actions: [MobileAction]) async throws(ActionError) {}
        func updateConversationToolbarActions(actions: [MobileAction]) async throws(ActionError) {}
        func updateMessageToolbarActions(actions: [MobileAction]) async throws(ActionError) {}
        func getAllListActions() -> [MobileAction] { [] }
        func getAllMessageActions() -> [MobileAction] { [] }
        func getAllConversationActions() -> [MobileAction] { [] }
    }
#endif
