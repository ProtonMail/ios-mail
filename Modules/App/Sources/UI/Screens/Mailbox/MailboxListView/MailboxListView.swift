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

extension MailboxBarsState {
    var topBarState: MailboxTopBarState? {
        switch visibilityMode {
        case .regular:
            switch spamTrashToggleState {
            case .hidden:
                nil
            case .visible(let isSelected):
                .includeSpamTrash(isSelected: isSelected)
            }
        case .selectionMode:
            .selectionMode(selectAll)
        }
    }
}

struct MailboxListView: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    @ObservedObject private var model: MailboxModel
    private let mailUserSession: MailUserSession

    @State private var isListAtTop: Bool = true

    init(model: MailboxModel, mailUserSession: MailUserSession) {
        self.model = model
        self.mailUserSession = mailUserSession
    }

    var body: some View {
        VStack(spacing: .zero) {
            if #unavailable(iOS 26) {
                topBar()
            }

            mailboxListView()
                .modify { view in
                    if #available(iOS 26, *) {
                        view
                            .mailboxTopSafeAreaBar(state: model.state.barsState.topBarState, onEvent: handleTopBarEvent)
                    }
                }
        }
        .onChange(of: model.state.barsState.unreadButtonState.isSelected) { model.onUnreadFilterChange() }
        .onChange(of: model.state.barsState.spamTrashToggleState) { model.onIncludeSpamTrashFilterChange() }
    }

    private func handleTopBarEvent(_ event: MailboxTopBarEvent) {
        switch event {
        case .spamTrashToggleTapped:
            model.state.barsState.spamTrashToggleState = model.state.barsState.spamTrashToggleState.toggled()
        case .selectAllTapped:
            model.onSelectAllTapped()
        }
    }
}

extension MailboxListView {
    private func mailboxItemListViewConfiguration() -> MailboxItemsListViewConfiguration {
        var config = MailboxItemsListViewConfiguration(
            dataSource: model.paginatedDataSource,
            selectionState: model.selectionMode.selectionState,
            itemTypeForActionBar: model.viewMode.itemType,
            systemLabel: model.selectedMailbox.systemFolder
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
                NoResultsView(
                    variant: model.selectedMailbox.emptyScreenVariant(
                        isUnreadFilterOn: model.state.barsState.unreadButtonState.isSelected
                    ))
            },
            emptyFolderBanner: $model.emptyFolderBanner,
            mailUserSession: mailUserSession,
            mailbox: model.mailbox,
            liquidComposeButton: {
                LiquidComposeButton {
                    model.createDraft()
                }
            }
        )
        .animation(.default, value: isListAtTop)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: model.selectedMailbox) { _, _ in
            self.isListAtTop = true
        }
        .onChange(of: model.state.barsState.unreadButtonState.isSelected) { _, _ in
            self.isListAtTop = true
        }
        .onLoad {
            model.onLoad()
        }
    }

    @ViewBuilder
    private func topBar() -> some View {
        if let viewModel = model.state.barsState.topBarState {
            MailboxTopBarView(state: viewModel, onEvent: handleTopBarEvent)
                .background(DS.Color.Background.norm.shadow(DS.Shadows.raisedBottom, isVisible: !isListAtTop))
                .zIndex(1)
        }
    }
}

#Preview {
    let route: AppRouteState = .init(route: .mailbox(selectedMailbox: .inbox))

    return MailboxListView(
        model: .init(
            mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
            userSession: .dummy,
            appRoute: route,
            draftPresenter: .dummy()
        ),
        mailUserSession: .dummy
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

private extension SystemLabel {
    func emptyScreenVariant(isUnreadFilterOn: Bool) -> NoResultsView.Variant {
        switch self {
        case .inbox, .allDrafts, .allSent, .sent, .trash, .spam, .allMail, .archive, .drafts, .starred, .scheduled,
            .almostAllMail, .snoozed, .categorySocial, .categoryPromotions, .categoryUpdates, .categoryForums,
            .categoryDefault, .blocked, .pinned, .categoryNewsletter, .categoryTransactions:
            .mailbox(isUnreadFilterOn: isUnreadFilterOn)
        case .outbox:
            .outbox
        }
    }
}
