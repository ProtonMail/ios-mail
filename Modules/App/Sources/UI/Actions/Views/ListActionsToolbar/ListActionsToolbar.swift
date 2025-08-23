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
import proton_app_uniffi
import SwiftUI

extension View {
    func listActionsToolbar(
        state: ListActionsToolbarState,
        availableActions: AvailableListToolbarActions,
        itemTypeForActionBar: MailboxItemType,
        mailUserSession: MailUserSession,
        selectedItems: Binding<Set<MailboxSelectedItem>>
    ) -> some View {
        modifier(
            ListActionBarViewModifier(
                state: state,
                availableActions: availableActions,
                itemTypeForActionBar: itemTypeForActionBar,
                mailUserSession: mailUserSession,
                selectedItems: selectedItems
            ))
    }
}

private struct ListActionBarViewModifier: ViewModifier {
    @Binding var selectedItems: Set<MailboxSelectedItem>
    @EnvironmentObject var mailbox: Mailbox
    @EnvironmentObject var toastStateStore: ToastStateStore
    @Environment(\.refreshToolbar) var refreshToolbarNotifier
    private let state: ListActionsToolbarState
    private let itemTypeForActionBar: MailboxItemType
    private let availableActions: AvailableListToolbarActions
    private let deleteActions: DeleteActions
    private let moveToActions: MoveToActions
    private let mailUserSession: MailUserSession
    private let starActionPerformerActions: StarActionPerformerActions
    private let readActionPerformerActions: ReadActionPerformerActions

    init(
        state: ListActionsToolbarState,
        availableActions: AvailableListToolbarActions,
        starActionPerformerActions: StarActionPerformerActions = .productionInstance,
        readActionPerformerActions: ReadActionPerformerActions = .productionInstance,
        deleteActions: DeleteActions = .productionInstance,
        moveToActions: MoveToActions = .productionInstance,
        itemTypeForActionBar: MailboxItemType,
        mailUserSession: MailUserSession,
        selectedItems: Binding<Set<MailboxSelectedItem>>
    ) {
        self._selectedItems = selectedItems
        self.state = state
        self.itemTypeForActionBar = itemTypeForActionBar
        self.availableActions = availableActions
        self.deleteActions = deleteActions
        self.moveToActions = moveToActions
        self.mailUserSession = mailUserSession
        self.starActionPerformerActions = starActionPerformerActions
        self.readActionPerformerActions = readActionPerformerActions
    }

    func body(content: Content) -> some View {
        StoreView(
            store: ListActionsToolbarStore(
                state: state,
                availableActions: availableActions,
                starActionPerformerActions: starActionPerformerActions,
                readActionPerformerActions: readActionPerformerActions,
                deleteActions: deleteActions,
                moveToActions: moveToActions,
                itemTypeForActionBar: itemTypeForActionBar,
                mailUserSession: mailUserSession,
                mailbox: mailbox,
                toastStateStore: toastStateStore
            )
        ) { state, store in
            content
                .toolbar {
                    toolbarContent(state: state, store: store)
                }
                .bottomToolbarStyle()
                .onChange(of: selectedItems) { oldValue, newValue in
                    if oldValue != newValue {
                        store.handle(action: .listItemsSelectionUpdated(ids: selectedItemsIDs))
                    }
                }
                .onLoad {
                    store.handle(action: .listItemsSelectionUpdated(ids: selectedItemsIDs))
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
                .sheet(item: store.binding(\.moreActionSheetPresented)) { state in
                    ListActionsToolbarMoreSheet(state: state) { action in
                        store.handle(action: .moreSheetAction(action, ids: selectedItemsIDs))
                    } editToolbarTapped: {
                        store.handle(action: .editToolbarTapped)
                    }
                    .alert(model: store.binding(\.moreDeleteConfirmationAlert))
                    .sheet(isPresented: store.binding(\.isEditToolbarSheetPresented)) {
                        EditToolbarScreen(state: .initial(toolbarType: .list), customizeToolbarService: mailUserSession)
                    }
                }
                .sheet(isPresented: store.binding(\.isSnoozeSheetPresented)) {
                    SnoozeView(
                        state: .initial(
                            screen: .main,
                            labelId: mailbox.labelId(),
                            conversationIDs: selectedItemsIDs
                        ))
                }
                .onReceive(refreshToolbarNotifier.refreshToolbar) { toolbarType in
                    if toolbarType == .list {
                        store.handle(action: .listItemsSelectionUpdated(ids: selectedItemsIDs))
                    }
                }
                .alert(model: store.binding(\.deleteConfirmationAlert))
        }
        .id(MailboxIdentifiaction(viewMode: mailbox.viewMode(), id: mailbox.labelId()))
    }

    // MARK: - Private

    private var selectedItemsIDs: [ID] {
        selectedItems.map(\.id)
    }

    private func toolbarContent(
        state: ListActionsToolbarState,
        store: ListActionsToolbarStore
    ) -> some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            HStack {
                ForEachEnumerated(state.bottomBarActions, id: \.element) { action, index in
                    if index == 0 {
                        Spacer()
                    }
                    Button(action: { store.handle(action: .actionSelected(action, ids: selectedItemsIDs)) }) {
                        action.displayData.image
                            .foregroundStyle(DS.Color.Icon.weak)
                    }
                    .accessibilityIdentifier(MailboxActionBarViewIdentifiers.button(index: index))
                    Spacer()
                }
            }
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { toolbarHeight in
                let bottomSafeAreaToRecreate = DS.Spacing.large
                toastStateStore.state.bottomBar.height = toolbarHeight + bottomSafeAreaToRecreate
            }
            .onAppear {
                toastStateStore.state.bottomBar.isVisible = true
            }
            .onDisappear {
                toastStateStore.state.bottomBar.isVisible = false
            }
        }
    }

}

// MARK: Accessibility

private struct MailboxActionBarViewIdentifiers {
    static let rootItem = "mailbox.actionBar.rootItem"

    static func button(index: Int) -> String {
        let number = index + 1
        return "mailbox.actionBar.button\(number)"
    }
}

private struct MailboxIdentifiaction: Hashable {
    let viewMode: ViewMode
    let id: ID
}
