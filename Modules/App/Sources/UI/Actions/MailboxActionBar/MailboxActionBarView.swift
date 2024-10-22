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

import DesignSystem
import proton_app_uniffi
import SwiftUI

struct MailboxActionBarView: View {
    @Binding var selectedItems: Set<ID>
    @EnvironmentObject var mailbox: Mailbox
    @StateObject var store: MailboxActionBarStateStore

    init(
        state: MailboxActionBarState,
        availableActions: AvailableMailboxActionBarActions,
        selectedItems: Binding<Set<ID>>
    ) {
        self._selectedItems = selectedItems
        self._store = StateObject(wrappedValue: .init(state: state, availableActions: availableActions))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack(alignment: .center) {
                    Spacer()
                    ForEach(store.state.visibleActions, id: \.self) { action in
                        Button(action: {
                            store.handle(
                                action: .actionSelected(
                                    action,
                                    ids: selectedItems,
                                    mailbox: mailbox,
                                    itemType: itemType
                                )
                            )
                        }) {
                            Image(action.displayData.icon)
                                .foregroundStyle(DS.Color.Icon.weak)
                        }
                        Spacer()
                    }
                }
                .frame(
                    width: min(geometry.size.width, geometry.size.height), 
                    height: 45 + geometry.safeAreaInsets.bottom
                )
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .compositingGroup()
                .shadow(radius: 2)
                .tint(DS.Color.Text.norm)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(MailboxActionBarViewIdentifiers.rootItem)
                .onChange(of: selectedItems) { oldValue, newValue in
                    if oldValue != newValue {
                        store.handle(
                            action: .mailboxItemsSelectionUpdated(newValue, mailbox: mailbox, itemType: itemType)
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
                            action: .moreSheetAction(action, ids: selectedItems, mailbox: mailbox, itemType: itemType)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Private

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

// MARK: Accessibility

private struct MailboxActionBarViewIdentifiers {
    static let rootItem = "mailbox.actionBar.rootItem"
    static let button1 = "mailbox.actionBar.button1"
    static let button2 = "mailbox.actionBar.button2"
    static let button3 = "mailbox.actionBar.button3"
    static let button4 = "mailbox.actionBar.button4"
    static let button5 = "mailbox.actionBar.button5"
}
