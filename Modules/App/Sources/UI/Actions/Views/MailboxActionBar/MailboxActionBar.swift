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
    func mailboxActionBar(
        state: MailboxActionBarState,
        availableActions: AvailableMailboxActionBarActions,
        itemTypeForActionBar: MailboxItemType,
        mailUserSession: MailUserSession,
        selectedItems: Binding<Set<MailboxSelectedItem>>
    ) -> some View {
        modifier(
            MailboxActionBarViewModifier(
                state: state,
                availableActions: availableActions,
                itemTypeForActionBar: itemTypeForActionBar,
                mailUserSession: mailUserSession,
                selectedItems: selectedItems
            ))
    }
}

private struct MailboxActionBarViewModifier: ViewModifier {
    @Binding var selectedItems: Set<MailboxSelectedItem>
    @EnvironmentObject var mailbox: Mailbox
    @EnvironmentObject var toastStateStore: ToastStateStore
    private let state: MailboxActionBarState
    private let itemTypeForActionBar: MailboxItemType
    private let availableActions: AvailableMailboxActionBarActions
    private let deleteActions: DeleteActions
    private let moveToActions: MoveToActions
    private let mailUserSession: MailUserSession
    private let starActionPerformerActions: StarActionPerformerActions
    private let readActionPerformerActions: ReadActionPerformerActions

    init(
        state: MailboxActionBarState,
        availableActions: AvailableMailboxActionBarActions,
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
            store: MailboxActionBarStateStore(
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
                        store.handle(action: .mailboxItemsSelectionUpdated(ids: selectedItemsIDs))
                    }
                }
                .onLoad {
                    store.handle(action: .mailboxItemsSelectionUpdated(ids: selectedItemsIDs))
                }
                .labelAsSheet(mailbox: { mailbox }, input: store.binding(\.labelAsSheetPresented))
                .moveToSheet(mailbox: { mailbox }, input: store.binding(\.moveToSheetPresented), navigation: { _ in })
                .sheet(item: store.binding(\.moreActionSheetPresented)) { state in
                    MailboxActionBarMoreSheet(state: state) { action in
                        store.handle(action: .moreSheetAction(action, ids: selectedItemsIDs))
                    }
                    .alert(model: store.binding(\.moreDeleteConfirmationAlert))
                }
                .sheet(isPresented: store.binding(\.isSnoozeSheetPresented)) {
                    SnoozeView(state: .initial(
                        screen: .main,
                        labelId: mailbox.labelId(),
                        conversationIDs: selectedItemsIDs
                    ))
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
        state: MailboxActionBarState,
        store: MailboxActionBarStateStore
    ) -> some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            HStack {
                ForEachEnumerated(state.bottomBarActions, id: \.element) { action, index in
                    if index == 0 {
                        Spacer()
                    }
                    Button(action: { store.handle(action: .actionSelected(action, ids: selectedItemsIDs)) }) {
                        action.displayData.icon
                            .foregroundStyle(DS.Color.Icon.weak)
                    }
                    .accessibilityIdentifier(MailboxActionBarViewIdentifiers.button(index: index))
                    Spacer()
                }
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
