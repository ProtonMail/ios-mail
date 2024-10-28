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
    @StateObject var store: MailboxActionBarStateStore

    init(
        state: MailboxActionBarState,
        availableActions: AvailableMailboxActionBarActions,
        starActionPerformerWrapper: StarActionPerformerWrapper = .productionInstance(),
        mailUserSession: MailUserSession = AppContext.shared.userSession,
        selectedItems: Binding<Set<MailboxSelectedItem>>
    ) {
        self._selectedItems = selectedItems
        self._store = StateObject(wrappedValue: .init(
            state: state,
            availableActions: availableActions,
            starActionPerformerWrapper: starActionPerformerWrapper,
            mailUserSession: mailUserSession
        ))
    }

    var body: some View {
        BottomActionBarView(actions: store.state.bottomBarActions) { action in
            store.handle(action: .actionSelected(action, ids: selectedItemsIDs, mailbox: mailbox, itemType: itemType))
        }
        .onChange(of: selectedItems) { oldValue, newValue in
            if oldValue != newValue {
                store.handle(
                    action: .mailboxItemsSelectionUpdated(
                        selectedItemsIDs,
                        mailbox: mailbox,
                        itemType: itemType
                    )
                )
            }
        }
        .sheet(item: $store.state.labelAsSheetPresented) { input in
            labelAsSheet(input: input)
        }
        .sheet(item: $store.state.moveToSheetPresented) { input in
            moveToSheet(input: input)
        }
        .sheet(item: $store.state.moreActionSheetPresented) { state in
            MailboxActionBarMoreSheet(state: state) { action in
                store.handle(
                    action: .moreSheetAction(
                        action,
                        ids: selectedItemsIDs,
                        mailbox: mailbox,
                        itemType: itemType
                    )
                )
            }
        }
    }

    // MARK: - Private

    private var selectedItemsIDs: Set<ID> {
        Set(selectedItems.map(\.id))
    }

    private var itemType: MailboxItemType {
        switch mailbox.viewMode() {
        case .conversations:
            .conversation
        case .messages:
            .message
        }
    }

    private func labelAsSheet(input: ActionSheetInput) -> some View {
        let model = LabelAsSheetModel(
            input: input,
            mailbox: mailbox,
            availableLabelAsActions: .productionInstance
        ) {
            store.handle(action: .dismissLabelAsSheet)
        }
        return LabelAsSheet(model: model)
    }

    private func moveToSheet(input: ActionSheetInput) -> some View {
        let model = MoveToSheetModel(
            input: input,
            mailbox: mailbox,
            availableMoveToActions: .productionInstance
        ) {
            store.handle(action: .dismissMoveToSheet)
        }
        return MoveToSheet(model: model)
    }
}

#Preview {
    MailboxActionBarView(
        state: MailboxActionBarPreviewProvider.state(),
        availableActions: MailboxActionBarPreviewProvider.availableActions(),
        selectedItems: .constant([])
    )
}
