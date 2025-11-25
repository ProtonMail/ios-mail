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
    ///
    /// The modifier is applied via `background(Color.clear)` **on purpose** to
    /// constrain view invalidation when the active `Mailbox` (and its
    /// `labelId`) changes. The action bar must be re-rendered and its
    /// `ListActionsToolbarStore` `@StateObject` recreated on each mailbox change
    /// to ensure the correct `labelId` is used under the hood—without forcing
    /// unnecessary re-renders of the surrounding view hierarchy.
    func listActionsToolbar(
        initialState: ListActionsToolbarState,
        availableActions: AvailableListToolbarActions,
        itemTypeForActionBar: MailboxItemType,
        mailUserSession: MailUserSession,
        selectedItems: Binding<Set<MailboxSelectedItem>>
    ) -> some View {
        background(
            Color.clear
                .modifier(
                    ListActionBarViewModifier(
                        initialState: initialState,
                        availableActions: availableActions,
                        itemTypeForActionBar: itemTypeForActionBar,
                        mailUserSession: mailUserSession,
                        selectedItems: selectedItems
                    )
                ))
    }
}

private struct ListActionBarViewModifier: ViewModifier {
    typealias State = ListActionsToolbarState
    typealias Store = ListActionsToolbarStore

    @Binding var selectedItems: Set<MailboxSelectedItem>
    @EnvironmentObject var mailbox: Mailbox
    @EnvironmentObject var toastStateStore: ToastStateStore
    @EnvironmentObject var refreshToolbarNotifier: RefreshToolbarNotifier
    private let initialState: ListActionsToolbarState
    private let itemTypeForActionBar: MailboxItemType
    private let availableActions: AvailableListToolbarActions
    private let deleteActions: DeleteActions
    private let moveToActions: MoveToActions
    private let mailUserSession: MailUserSession
    private let starActionPerformerActions: StarActionPerformerActions
    private let readActionPerformerActions: ReadActionPerformerActions

    init(
        initialState: ListActionsToolbarState,
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
        self.initialState = initialState
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
                state: initialState,
                availableActions: availableActions,
                starActionPerformerActions: starActionPerformerActions,
                readActionPerformerActions: readActionPerformerActions,
                deleteActions: deleteActions,
                moveToActions: moveToActions,
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
                        store.handle(
                            action: .listItemsSelectionUpdated(
                                ids: selectedItemsIDs,
                                itemType: itemTypeForActionBar
                            ))
                    }
                }
                .onLoad {
                    store.handle(
                        action: .listItemsSelectionUpdated(
                            ids: selectedItemsIDs,
                            itemType: itemTypeForActionBar
                        ))
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
                            conversationIDs: selectedItemsIDs
                        ))
                }
                .onReceive(refreshToolbarNotifier.refreshToolbar) { toolbarType in
                    if toolbarType == .list {
                        store.handle(
                            action: .listItemsSelectionUpdated(
                                ids: selectedItemsIDs,
                                itemType: itemTypeForActionBar
                            ))
                    }
                }
                .alert(model: store.binding(\.deleteConfirmationAlert))
        }
        .id(MailboxIdentifiaction(viewMode: mailbox.viewMode(), id: mailbox.labelId()))  // FIXME: - Fix spam / trash filter
    }

    // MARK: - Private

    private var selectedItemsIDs: [ID] {
        selectedItems.map(\.id)
    }

    private func toolbarContent(state: State, store: Store) -> some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Spacer()
            ForEach(state.bottomBarActions, id: \.self) { action in
                toolbarItem(for: action, state: state, store: store)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func toolbarItem(
        for action: ListActions,
        state: State,
        store: Store
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
                                store.handle(
                                    action: .actionSelected(
                                        action,
                                        ids: selectedItemsIDs,
                                        itemType: itemTypeForActionBar
                                    ))
                            }
                        }
                    }
                },
                label: {
                    action.displayData.image
                        .foregroundStyle(DS.Color.Icon.weak)
                })
        } else {
            Button(action: {
                store.handle(
                    action: .actionSelected(
                        action,
                        ids: selectedItemsIDs,
                        itemType: itemTypeForActionBar)
                )
            }) {
                action.displayData.image
                    .foregroundStyle(DS.Color.Icon.weak)
            }
        }
    }
}

private struct MailboxIdentifiaction: Hashable {
    let viewMode: ViewMode
    let id: ID
}
