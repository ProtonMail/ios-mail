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
import SwiftUI

struct MailboxListView: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    @EnvironmentObject private var userSettings: UserSettings
    @ObservedObject private var model: MailboxModel

    @State private var didAppearBefore = false
    @State private var pullToRefreshOffset: CGFloat = 0.0
    @Binding private var isListAtTop: Bool
    private let customLabelModel: CustomLabelModel

    init(isListAtTop: Binding<Bool>, model: MailboxModel, customLabelModel: CustomLabelModel) {
        self._isListAtTop = isListAtTop
        self.model = model
        self.customLabelModel = customLabelModel
    }

    var body: some View {
        MailboxItemsListView(
            config: mailboxItemListViewConfiguration(),
            headerView:  { unreadFilterView() },
            emptyView: { MailboxEmptyView()}
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: model.selectedMailbox) { _, _ in
            self.isListAtTop = true
        }
        .task {
            guard !didAppearBefore else { return }
            didAppearBefore = true
            await model.onViewDidAppear()
        }
    }
}

extension MailboxListView {

    private func disableSwipeActionIfNeeded(_ swipeAction: SwipeAction) -> SwipeAction {
        swipeAction.isActionAssigned(systemFolder: model.selectedMailbox.systemFolder) 
        ? swipeAction
        : .none
    }

    private func mailboxItemListViewConfiguration() -> MailboxItemsListViewConfiguration {
        var config = MailboxItemsListViewConfiguration(
            dataSource: model.paginatedDataSource,
            selectionState: model.selectionMode.selectionState,
            actionBar: MailboxItemsListActionBar(
                selectedMailbox: model.selectedMailbox,
                customLabelModel: customLabelModel,
                mailboxActionable: model
            )
        )

        config.swipeActions = .init(
            leadingSwipe: { disableSwipeActionIfNeeded(userSettings.leadingSwipeAction) },
            trailingSwipe: { disableSwipeActionIfNeeded(userSettings.trailingSwipeAction) }
        )
        
        config.listEventHandler = .init(
            listAtTop: { isListAtTop = $0 },
            pullToRefresh: { await model.onPullToRefresh() }
        )
        
        config.cellEventHandler = .init(
            onCellEvent: { [weak model] event, item in
                switch event {
                case .onTap:
                    model?.onMailboxItemTap(item: item)
                case .onLongPress:
                    model?.onLongPress(mailboxItem: item)
                case .onSelectedChange(let isSelected):
                    model?.onMailboxItemSelectionChange(item: item, isSelected: isSelected)
                case .onStarredChange(let isStarred):
                    model?.onMailboxItemStarChange(item: item, isStarred: isStarred)
                case .onAttachmentTap(let attachmentId):
                    model?.onMailboxItemAttachmentTap(attachmentId: attachmentId, for: item)
                }
            },
            onSwipeAction: { action, itemId in
                toastStateStore.present(toast: .comingSoon)
//                    model?.onMailboxItemAction(action, itemIds: ids)
            }
        )
        
        return config
    }

    private func unreadFilterView() -> some View {
        UnreadFilterBarView(isSelected: $model.state.isUnreadSelected, unread: model.state.unreadItemsCount)
            .buttonStyle(PlainButtonStyle())
            .listRowBackground(DS.Color.Background.norm)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
    }
}

#Preview {
    let route: AppRouteState = .init(route: .mailbox(selectedMailbox: .inbox))

    return MailboxListView(
        isListAtTop: .constant(true),
        model: .init(
            mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
            appRoute: route
        ),
        customLabelModel: CustomLabelModel()
    )
}
