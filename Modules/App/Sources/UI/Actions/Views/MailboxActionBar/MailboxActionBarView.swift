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

struct MailboxActionBarView: View {
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
        mailUserSession: MailUserSession = AppContext.shared.userSession,
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

    var body: some View {
        StoreView(store: MailboxActionBarStateStore(
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
        )) { state, store in
            BottomActionBarView(actions: state.bottomBarActions) { action in
                store.handle(action: .actionSelected(action, ids: selectedItemsIDs))
            }
            .onChange(of: selectedItems) { oldValue, newValue in
                if oldValue != newValue {
                    store.handle(action: .mailboxItemsSelectionUpdated(ids: selectedItemsIDs))
                }
            }
            .onLoad {
                store.handle(action: .mailboxItemsSelectionUpdated(ids: selectedItemsIDs))
            }
            .sheet(item: store.binding(\.labelAsSheetPresented)) { input in
                labelAsSheet(input: input, actionHandler: store.handle)
            }
            .sheet(item: store.binding(\.moveToSheetPresented)) { input in
                moveToSheet(input: input, actionHandler: store.handle)
            }
            .sheet(item: store.binding(\.moreActionSheetPresented)) { state in
                MailboxActionBarMoreSheet(state: state) { action in
                    store.handle(action: .moreSheetAction(action, ids: selectedItemsIDs))
                }
                .alert(model: store.binding(\.moreDeleteConfirmationAlert)) { action in
                    store.handle(action: .alertActionTapped(action, ids: selectedItemsIDs))
                }
            }
            .alert(model: store.binding(\.deleteConfirmationAlert)) { action in
                store.handle(action: .alertActionTapped(action, ids: selectedItemsIDs))
            }
        }
    }

    // MARK: - Private

    private var selectedItemsIDs: [ID] {
        selectedItems.map(\.id)
    }

    private func labelAsSheet(
        input: ActionSheetInput,
        actionHandler: @escaping (MailboxActionBarAction) -> Void
    ) -> some View {
        let model = LabelAsSheetModel(
            input: input,
            mailbox: mailbox,
            availableLabelAsActions: .productionInstance, 
            labelAsActions: .productionInstance
        ) {
            actionHandler(.dismissLabelAsSheet)
        }
        return LabelAsSheet(model: model)
    }

    private func moveToSheet(
        input: ActionSheetInput,
        actionHandler: @escaping (MailboxActionBarAction) -> Void
    ) -> some View {
        MoveToSheet(
            input: input,
            mailbox: mailbox,
            availableMoveToActions: .productionInstance,
            moveToActions: .productionInstance
        ) { _ in
            actionHandler(.dismissMoveToSheet)
        }
    }
}

#Preview {
    MailboxActionBarView(
        state: MailboxActionBarPreviewProvider.state(),
        availableActions: MailboxActionBarPreviewProvider.availableActions(),
        itemTypeForActionBar: .conversation,
        selectedItems: .constant([])
    )
}
