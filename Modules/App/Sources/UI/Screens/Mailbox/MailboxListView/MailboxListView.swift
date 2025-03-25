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

import InboxDesignSystem
import InboxCoreUI
import SwiftUI

struct MailboxListView: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    @ObservedObject private var model: MailboxModel

    @Binding private var isListAtTop: Bool

    init(isListAtTop: Binding<Bool>, model: MailboxModel) {
        self._isListAtTop = isListAtTop
        self.model = model
    }

    var body: some View {
        VStack(spacing: .zero) {
            unreadFilter()
            mailboxListView()
        }
        .onChange(of: model.state.filterBar.isUnreadButtonSelected, { model.onUnreadFilterChange() })
    }
}

extension MailboxListView {

    private func mailboxItemListViewConfiguration() -> MailboxItemsListViewConfiguration {
        var config = MailboxItemsListViewConfiguration(
            dataSource: model.paginatedDataSource,
            selectionState: model.selectionMode.selectionState,
            itemTypeForActionBar: model.viewMode.itemType,
            isOutboxLocation: model.isOutbox
        )

        config.swipeActions = model.state.swipeActions

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
            onSwipeAction: { [weak model] context in
                model?.onMailboxItemAction(context, toastStateStore: toastStateStore)
            }
        )
        
        return config
    }

    private func mailboxListView() -> some View {
        MailboxItemsListView(
            config: mailboxItemListViewConfiguration(),
            emptyView: {
                NoResultsView(variant: model.selectedMailbox.emptyScreenVariant(
                    isUnreadFilterOn: model.state.filterBar.isUnreadButtonSelected
                ))
            }
        )
        .injectIfNotNil(model.mailbox)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: model.selectedMailbox) { _, _ in
            self.isListAtTop = true
        }
        .onChange(of: model.state.filterBar.isUnreadButtonSelected) { _, _ in
            self.isListAtTop = true
        }
        .onLoad {
            model.onLoad()
        }
    }

    @ViewBuilder
    private func unreadFilter() -> some View {
        UnreadFilterBarView(state: $model.state.filterBar)
            .background(
                DS.Color.Background.norm
                    .shadow(DS.Shadows.raisedBottom, isVisible: !isListAtTop)
            )
            .zIndex(1)
    }
}

#Preview {
    let route: AppRouteState = .init(route: .mailbox(selectedMailbox: .inbox))

    return MailboxListView(
        isListAtTop: .constant(true),
        model: .init(
            mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
            appRoute: route,
            draftPresenter: .dummy
        )
    )
}

private extension SelectedMailbox {

    func emptyScreenVariant(isUnreadFilterOn: Bool) -> NoResultsView.Variant {
        switch self {
        case .inbox, .customLabel, .customFolder:
            .mailbox(isUnreadFilterOn: isUnreadFilterOn)
        case .systemFolder(_, let systemFolder):
            systemFolder.emptyScreenVariant(isUnreadFilterOn: isUnreadFilterOn)
        }
    }

}

private extension SystemFolderLabel {

    func emptyScreenVariant(isUnreadFilterOn: Bool) -> NoResultsView.Variant {
        switch self {
        case .inbox, .allDrafts, .allSent, .sent, .trash, .spam, .allMail, .archive, .drafts, .starred, .scheduled,
                .almostAllMail, .snoozed, .categorySocial, .categoryPromotions, .catergoryUpdates, .categoryForums,
                .categoryDefault, .blocked, .pinned:
            .mailbox(isUnreadFilterOn: isUnreadFilterOn)
        case .outbox:
            .outbox
        }
    }

}

