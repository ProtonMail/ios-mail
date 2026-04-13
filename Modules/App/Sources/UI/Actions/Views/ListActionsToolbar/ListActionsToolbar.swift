// Copyright (c) 2024 Proton Technologies AG
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
import InboxDesignSystem
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

extension View {
    /// Attaches the list actions toolbar to this view.
    func listActionsToolbar<ComposeButton: ToolbarContent>(
        initialState: ListActionsToolbarState,
        selectedIds: [ID],
        availableActions: AvailableListToolbarActions,
        mailUserSession: MailUserSession,
        mailbox: Mailbox,
        toastStateStore: ToastStateStore,
        refreshToolbarNotifier: RefreshToolbarNotifier,
        liquidComposeButton: (() -> ComposeButton)?
    ) -> some View {
        modifier(
            ListActionBarViewModifier(
                initialState: initialState,
                selectedIds: selectedIds,
                availableActions: availableActions,
                mailUserSession: mailUserSession,
                mailbox: mailbox,
                toastStateStore: toastStateStore,
                refreshToolbarNotifier: refreshToolbarNotifier,
                liquidComposeButton: liquidComposeButton
            )
        )
    }
}

private struct ListActionBarViewModifier<ComposeButton: ToolbarContent>: ViewModifier {
    @StateObject private var store: ListActionsToolbarStore

    let selectedIds: [ID]
    let mailbox: Mailbox
    let refreshToolbarNotifier: RefreshToolbarNotifier
    let mailUserSession: MailUserSession
    let liquidComposeButton: ComposeButton?

    init(
        initialState: ListActionsToolbarState,
        selectedIds: [ID],
        availableActions: AvailableListToolbarActions,
        starActionPerformerActions: StarActionPerformerActions = .productionInstance,
        readActionPerformerActions: ReadActionPerformerActions = .productionInstance,
        deleteActions: DeleteActions = .productionInstance,
        moveToActions: MoveToActions = .productionInstance,
        mailUserSession: MailUserSession,
        mailbox: Mailbox,
        toastStateStore: ToastStateStore,
        refreshToolbarNotifier: RefreshToolbarNotifier,
        liquidComposeButton: (() -> ComposeButton)?
    ) {
        self.selectedIds = selectedIds
        self.mailbox = mailbox
        self.refreshToolbarNotifier = refreshToolbarNotifier
        self.mailUserSession = mailUserSession
        self.liquidComposeButton = liquidComposeButton?()
        self._store = StateObject(
            wrappedValue: ListActionsToolbarStore(
                state: initialState,
                availableActions: availableActions,
                starActionPerformerActions: starActionPerformerActions,
                readActionPerformerActions: readActionPerformerActions,
                deleteActions: deleteActions,
                moveToActions: moveToActions,
                mailUserSession: mailUserSession,
                mailbox: mailbox,
                toastStateStore: toastStateStore
            ))
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                toolbarContent(state: store.state, store: store)
            }
            .animation(.default, value: store.state.bottomBarActions)
            .bottomToolbarStyle()
            .onChange(of: selectedIds) { _, newValue in
                store.handle(action: .listItemsSelectionUpdated(ids: newValue))
            }
            .onLoad {
                store.handle(action: .listItemsSelectionUpdated(ids: selectedIds))
            }
            .labelAsSheet(
                mailbox: { mailbox },
                mailUserSession: mailUserSession,
                input: store.binding(\.labelAsSheetPresented)
            )
            .moveToSheet(
                mailbox: { mailbox },
                mailUserSession: mailUserSession,
                input: store.binding(\.moveToSheetPresented),
                navigation: { _ in
                    store.handle(action: .dismissMoveToSheet)
                }
            )
            .sheet(isPresented: store.binding(\.isEditToolbarSheetPresented)) {
                EditToolbarScreen(state: .initial(toolbarType: .list), customizeToolbarService: mailUserSession)
            }
            .sheet(isPresented: store.binding(\.isSnoozeSheetPresented)) {
                SnoozeView(
                    state: .initial(
                        screen: .main,
                        labelId: mailbox.labelId(),
                        conversationIDs: store.state.selectedIds
                    ))
            }
            .onReceive(refreshToolbarNotifier.refreshToolbar) { toolbarType in
                if toolbarType == .list {
                    store.handle(action: .listItemsSelectionUpdated(ids: store.state.selectedIds))
                }
            }
            .alert(model: store.binding(\.deleteConfirmationAlert))
            .onChange(of: MailboxIdentifiaction(viewMode: mailbox.viewMode(), id: mailbox.labelId())) { _, _ in
                store.handle(action: .mailboxChanged(mailbox))
            }
    }

    // MARK: - Private

    @ToolbarContentBuilder
    private func toolbarContent(state: ListActionsToolbarState, store: ListActionsToolbarStore) -> some ToolbarContent {
        if state.bottomBarActions.isEmpty == false {
            ToolbarItemGroup(placement: .bottomBar) {
                AdaptiveToolbarItemsLayout(items: state.bottomBarActions) { action in
                    toolbarItem(for: action, state: state, store: store)
                }
            }
        }

        if #available(iOS 26.0, *), state.bottomBarActions.isEmpty, let liquidComposeButton {
            ToolbarSpacer(.flexible, placement: .bottomBar)

            liquidComposeButton
        }
    }

    @ViewBuilder
    private func toolbarItem(
        for action: ListActions,
        state: ListActionsToolbarState,
        store: ListActionsToolbarStore
    ) -> some View {
        if action == .more {
            Menu(
                content: {
                    ActionMenuButton(displayData: InternalAction.editToolbar.displayData) {
                        store.handle(action: .editToolbarTapped)
                    }
                    Section {
                        ForEach(state.moreSheetOnlyActions.reversed(), id: \.self) { action in
                            ActionMenuButton(displayData: action.displayData) {
                                store.handle(action: .actionSelected(action, ids: store.state.selectedIds))
                            }
                        }
                    }
                },
                label: {
                    action.displayData.image
                        .foregroundStyle(DS.Color.Icon.norm)
                })
        } else {
            Button(action: {
                store.handle(action: .actionSelected(action, ids: store.state.selectedIds))
            }) {
                action.displayData.image
                    .foregroundStyle(DS.Color.Icon.norm)
            }
        }
    }
}

private struct MailboxIdentifiaction: Hashable {
    let viewMode: ViewMode
    let id: ID
}
