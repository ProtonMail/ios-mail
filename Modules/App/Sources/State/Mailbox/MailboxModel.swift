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

import AccountManager
import Combine
import Foundation
import SwiftUI
import proton_app_uniffi
import class UIKit.UIImage
import ProtonCoreUtilities

/**
 Source of truth for the Mailbox view showing mailbox items (conversations or messages).
 */
final class MailboxModel: ObservableObject {
    @Published var state: State = .init()
    let selectionMode: SelectionMode = .init()
    private(set) var selectedMailbox: SelectedMailbox

    private let mailSettingsLiveQuery: MailSettingLiveQuerying
    @ObservedObject private var appRoute: AppRouteState
    private var mailbox: Mailbox?
    private var messagePaginator: MessagePaginator?
    private var conversationPaginator: ConversationPaginator?
    lazy var paginatedDataSource = PaginatedListDataSource<MailboxItemCellUIModel>(
        fetchPage: { [unowned self] currentPage, pageSize in
            let result = await fetchNextPageItems(currentPage: currentPage)
            return result
        })
    private var unreadCountLiveQuery: UnreadItemsCountLiveQuery?
    private var paginatorCallback: LiveQueryCallbackWrapper = .init()
    private let dependencies: Dependencies
    private var cancellables = Set<AnyCancellable>()

    @NestedObservableObject var accountManagerCoordinator: AccountManagerCoordinator

    private var userSession: MailUserSession {
        dependencies.appContext.userSession
    }

    private var viewMode: ViewMode {
        mailbox?.viewMode() ?? .conversations
    }

    private var messagesShouldDisplaySenderEmail: Bool {
        let systemFolder = selectedMailbox.systemFolder
        return ![SystemFolderLabel.drafts, .allDrafts, .sent, .allSent, .scheduled]
            .contains(systemFolder)
    }

    private var itemsShouldShowLocation: Bool {
        let systemFolder = selectedMailbox.systemFolder
        let mailboxOfSpecificSystemFolder = [SystemFolderLabel.allMail, .almostAllMail, .starred].contains(systemFolder)
        return mailboxOfSpecificSystemFolder || selectedMailbox.isCustomLabel
    }

    init(
        mailSettingsLiveQuery: MailSettingLiveQuerying,
        appRoute: AppRouteState,
        openedItem: MailboxMessageSeed? = nil,
        dependencies: Dependencies = .init()
    ) {
        AppLogger.log(message: "MailboxModel init", category: .mailbox)
        self.mailSettingsLiveQuery = mailSettingsLiveQuery
        self.appRoute = appRoute
        self.selectedMailbox = appRoute.route.selectedMailbox ?? .inbox
        self.dependencies = dependencies
        self.accountManagerCoordinator = AccountManagerCoordinator(appContext: dependencies.appContext.mailSession)

        setUpBindings()
        setUpPaginatorCallback()

        if let openedItem = openedItem {
            state.navigationPath.append(openedItem)
        }
    }

    deinit {
        AppLogger.log(message: "MailboxModel deinit", category: .mailbox)
    }

    func onViewDidAppear() async {
        await updateMailboxAndPaginator()
    }
}

// MARK: Private

extension MailboxModel {

    private func setUpBindings() {
        appRoute
            .onSelectedMailboxChange
            .sink { [weak self] newSelectedMailbox in
                Task {
                    guard let self else { return }
                    self.selectedMailbox = newSelectedMailbox
                    await self.updateMailboxAndPaginator()
                }
            }
            .store(in: &cancellables)

        mailSettingsLiveQuery
            .viewModeHasChanged
            .sink { [weak self] _ in
                Task {
                    guard let self else { return }
                    AppLogger.log(message: "viewMode has changed", category: .mailbox)
                    await self.updateMailboxAndPaginator()
                }
            }
            .store(in: &cancellables)

        selectionMode
            .selectionState
            .$hasItems
            .sink { [weak self] hasItems in
                Task {
                    self?.state.showActionBar = hasItems
                    self?.updateMailboxTitle()
                    await self?.refreshMailboxItems()
                }
            }
            .store(in: &cancellables)
    }

    private func setUpPaginatorCallback() {
        paginatorCallback.delegate = { [weak self] in
            Task {
                AppLogger.log(message: "items paginator callback", category: .mailbox)
                await self?.refreshMailboxItems()
            }
        }
    }

    private func updateMailboxTitle() {
        let selectionMode = selectionMode
        let hasSelectedItems = selectionMode.selectionState.hasItems
        let selectedItemsCount = selectionMode.selectionState.selectedItems.count
        let selectedMailboxName = selectedMailbox.name

        state.mailboxTitle = hasSelectedItems 
        ? L10n.Mailbox.selected(emailsCount: selectedItemsCount)
        : selectedMailboxName
    }

    private func updateMailboxAndPaginator() async {
        guard let userSession = dependencies.appContext.activeUserSession else { return }
        do {
            updateMailboxTitle()
            await paginatedDataSource.resetToInitialState()

            let mailbox = selectedMailbox.isInbox
            ? try await Mailbox.inbox(ctx: userSession)
            : try await Mailbox(ctx: userSession, labelId: selectedMailbox.localId)
            self.mailbox = mailbox
            AppLogger.log(message: "mailbox view mode: \(mailbox.viewMode().description)", category: .mailbox)

            if mailbox.viewMode() == .messages {
                messagePaginator = try await paginateMessagesForLabel(
                    session: userSession,
                    labelId: mailbox.labelId(),
                    callback: paginatorCallback
                )
            } else {
                conversationPaginator = try await paginateConversationsForLabel(
                    session: userSession,
                    labelId: mailbox.labelId(),
                    callback: paginatorCallback
                )
            }
            await paginatedDataSource.fetchInitialPage()

            unreadCountLiveQuery = UnreadItemsCountLiveQuery(mailbox: mailbox) { [weak self] unreadCount in
                AppLogger.log(message: "unread count callback: \(unreadCount)", category: .mailbox)
                await MainActor.run {
                    self?.state.unreadItemsCount = unreadCount
                }
            }
            await unreadCountLiveQuery?.setUpLiveQuery()
        } catch {
            AppLogger.log(error: error, category: .mailbox)
            fatalError("failed to instantiate the Mailbox or Paginator object")
        }
    }

    private func fetchNextPageItems(currentPage: Int) async -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        guard let mailbox else {
            AppLogger.log(message: "no mailbox found when requesting a page", isError: true)
            return .init(newItems: [], isLastPage: true)
        }
        do {
            let result: PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult
            result = mailbox.viewMode() == .messages
            ? try await fetchNextPageMessages(currentPage: currentPage)
            : try await fetchNextPageConversations(currentPage: currentPage)
            AppLogger.logTemporarily(message: "page \(currentPage) returned \(result.newItems.count) items", category: .mailbox)
            return result
        } catch {
            AppLogger.log(error: error, category: .mailbox)
            return .init(newItems: paginatedDataSource.state.items, isLastPage: true)
        }
    }

    private func fetchNextPageMessages(currentPage: Int) async throws -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        guard let messagePaginator else {
            AppLogger.log(message: "no paginator found when fetching messages", category: .mailbox, isError: true)
            return .init(newItems: [], isLastPage: true)
        }
        AppLogger.logTemporarily(message: "fetching messages page \(currentPage)", category: .mailbox)

        let messages = try await messagePaginator.nextPage()
        let items = mailboxItems(messages: messages)
        return .init(newItems: items, isLastPage: !messagePaginator.hasNextPage())
    }

    private func fetchNextPageConversations(currentPage: Int) async throws -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        guard let conversationPaginator else {
            AppLogger.log(message: "no paginator found when fetching conversations", category: .mailbox, isError: true)
            return .init(newItems: [], isLastPage: true)
        }
        AppLogger.logTemporarily(message: "fetching conversations page \(currentPage)", category: .mailbox)

        let conversations = try await conversationPaginator.nextPage()
        let items = mailboxItems(conversations: conversations)
        return .init(newItems: items, isLastPage: !conversationPaginator.hasNextPage())
    }

    private func refreshMailboxItems() async {
        if viewMode == .messages {
            await refreshMessage()
        } else {
            await refreshConversations()
        }

        selectionMode.selectionModifier.refreshSelectedItemsStatus { itemIds in
            let selectedItems = paginatedDataSource.state.items
                .filter { itemIds.contains($0.id) }
                .map { $0.toSelectedItem() }
            return Set(selectedItems)
        }
    }

    private func refreshMessage() async {
        guard let messagePaginator else { return }
        do {
            let messages = try await messagePaginator.reload()
            let items = mailboxItems(messages: messages)
            AppLogger.logTemporarily(message: "refreshed messages before: \(paginatedDataSource.state.items.count) after: \(items.count)", category: .mailbox)
            await paginatedDataSource.updateItems(items)
        } catch {
            AppLogger.log(error: error, category: .mailbox)
        }
    }

    private func refreshConversations() async {
        guard let conversationPaginator else { return }
        do {
            let conversations = try await conversationPaginator.reload()
            let items = mailboxItems(conversations: conversations)
            AppLogger.logTemporarily(message: "refreshed conversations before: \(paginatedDataSource.state.items.count) after: \(items.count)", category: .mailbox)
            await paginatedDataSource.updateItems(items)
        } catch {
            AppLogger.log(error: error, category: .mailbox)
        }
    }

    private func mailboxItems(messages: [Message]) -> [MailboxItemCellUIModel] {
        let selectedIds = Set(selectionMode.selectionState.selectedItems.map(\.id))
        let displaySenderEmail = messagesShouldDisplaySenderEmail
        let showLocation = itemsShouldShowLocation
        return messages.map { message in
            message.toMailboxItemCellUIModel(
                selectedIds: selectedIds,
                displaySenderEmail: displaySenderEmail,
                showLocation: showLocation
            )
        }
    }

    private func mailboxItems(conversations: [Conversation]) -> [MailboxItemCellUIModel] {
        let selectedIds = Set(selectionMode.selectionState.selectedItems.map(\.id))
        let showLocation = itemsShouldShowLocation
        return conversations.map { conversation in
            conversation.toMailboxItemCellUIModel(selectedIds: selectedIds, showLocation: showLocation)
        }
    }
}

// MARK: Pull to refresh

extension MailboxModel {

    func onPullToRefresh() async {
        await dependencies.appContext.pollEventsAsync()
        let twoHundredsMilliseconds: UInt64 = 200_000_000
        try? await Task.sleep(nanoseconds: twoHundredsMilliseconds)
    }
}


// MARK: View actions

extension MailboxModel {

    private func applySelectionStateChangeInstead(mailboxItem: MailboxItemCellUIModel) {
        let isCurrentlySelected = selectionMode.selectionState.selectedItems.contains(mailboxItem.toSelectedItem())
        onMailboxItemSelectionChange(item: mailboxItem, isSelected: !isCurrentlySelected)
    }

    @MainActor
    func onMailboxItemTap(item: MailboxItemCellUIModel) {
        guard !selectionMode.selectionState.hasItems else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        state.navigationPath.append(item)
    }

    @MainActor
    func onLongPress(mailboxItem: MailboxItemCellUIModel) {
        guard !selectionMode.selectionState.hasItems else { return }
        onMailboxItemSelectionChange(item: mailboxItem, isSelected: true)
    }

    @MainActor
    func onMailboxItemSelectionChange(item: MailboxItemCellUIModel, isSelected: Bool) {
        isSelected
        ? selectionMode.selectionModifier.addMailboxItem(item.toSelectedItem())
        : selectionMode.selectionModifier.removeMailboxItem(item.toSelectedItem())
    }

    func onMailboxItemStarChange(item: MailboxItemCellUIModel, isStarred: Bool) {
        guard !selectionMode.selectionState.hasItems else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        isStarred ? actionStar(ids: [item.id]) : actionUnstar(ids: [item.id])
    }

    func onMailboxItemAttachmentTap(attachmentId: ID, for item: MailboxItemCellUIModel) {
        guard !selectionMode.selectionState.hasItems, let mailbox else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        state.attachmentPresented = AttachmentViewConfig(id: attachmentId, mailbox: mailbox)
    }

    func onMailboxItemAction(_ action: Action, itemIds: [ID]) {
        switch action {
        case .deletePermanently:
            actionDelete(ids: itemIds)
        case .markAsRead:
            actionUpdateReadStatus(to: .read, for: itemIds)
        case .markAsUnread:
            actionUpdateReadStatus(to: .unread, for: itemIds)
        case .moveToArchive:
            actionMoveTo(systemFolder: .archive, ids: itemIds)
        case .moveToInbox:
            actionMoveTo(systemFolder: .inbox, ids: itemIds)
        case .moveToSpam:
            actionMoveTo(systemFolder: .spam, ids: itemIds)
        case .moveToTrash:
            actionMoveTo(systemFolder: .trash, ids: itemIds)
        case .star:
            actionStar(ids: itemIds)
        case .unstar:
            actionUnstar(ids: itemIds)
        default:
            break
        }
    }
}

// MARK: conversation actions

extension MailboxModel {

    private func actionStar(ids: [ID]) {
        Task {
            do {
                try await starConversations(session: userSession, ids: ids)
            } catch {
                AppLogger.log(error: error, category: .mailboxActions)
            }
        }
    }

    private func actionUnstar(ids: [ID]) {
        Task {
            do {
                try await unstarConversations(session: userSession, ids: ids)
            } catch {
                AppLogger.log(error: error, category: .mailboxActions)
            }
        }
    }

    private func actionDelete(ids: [ID]) {
        AppLogger.log(message: "Conversation deletion \(ids)...", category: .mailboxActions)
        guard let mailbox else { return }
        Task {
            do {
                try await deleteConversations(mailbox: mailbox, conversationIds: ids)
            } catch {
                AppLogger.log(error: error, category: .mailboxActions)
            }
        }
    }

    private func actionMoveTo(systemFolder: SystemFolderLabel, ids: [ID]) {
        actionMoveTo(labelId: .init(value: UInt64(systemFolder.rawValue)), ids: ids)
    }

    private func actionMoveTo(labelId: ID, ids: [ID]) {
        guard let mailbox else { return }
        Task {
            do {
                try await moveConversations(mailbox: mailbox, labelId: labelId, ids: ids)
            } catch {
                AppLogger.log(error: error, category: .mailboxActions)
            }
        }
    }

    private func actionUpdateReadStatus(to newStatus: MailboxReadStatus, for ids: [ID]) {
        AppLogger.log(message: "Conversation set read status \(ids)...", category: .mailboxActions)
        guard let mailbox else { return }
        do {
            if case .read = newStatus {
                Task {
                    do {
                        try await markConversationsAsRead(session: userSession, ids: ids)
                    } catch {
                        AppLogger.log(error: error, category: .mailboxActions)
                    }
                }
            } else if case .unread = newStatus {
                Task {
                    do {
                        try await markConversationsAsUnread(mailbox: mailbox, ids: ids)
                    } catch {
                        AppLogger.log(error: error, category: .mailboxActions)
                    }
                }
            }
        }
    }

    private func actionApplyLabels(_ selectedLabels: Set<ID>, to ids: [ID]) {
        let selectedConversations = paginatedDataSource.state.items.filter({ $0.isSelected })
        if viewMode == .conversations {
            do {
                let existingLabelsInConversations = selectedConversations
                    .map(\.labelUIModel.allLabelIds)
                    .reduce(Set<ID>(), { $0.union($1) })

                existingLabelsInConversations.forEach { labelId in
                    Task {
                        do {
                            try await removeLabelFromConversations(
                                session: userSession,
                                labelId: labelId,
                                ids: selectedConversations.map(\.id)
                            )
                        } catch {
                            AppLogger.log(error: error, category: .mailboxActions)
                        }
                    }
                }

                selectedLabels.forEach { labelId in
                    Task {
                        do {
                            try await applyLabelToConversations(
                                session: userSession,
                                labelId: labelId,
                                ids: selectedConversations.map(\.id)
                            )
                        } catch {
                            AppLogger.log(error: error, category: .mailboxActions)
                        }
                    }
                }
            }
        } else {
            // TODO: actions for messages not ready
        }
    }
}

// MARK: MailboxActionable

extension MailboxModel: MailboxActionable {
    
    func labelsOfSelectedItems() -> [Set<ID>] {
        paginatedDataSource.state.items.filter({ $0.isSelected }).map(\.labelUIModel.allLabelIds)
    }

    func onActionTap(_ action: Action) {
        onMailboxItemAction(action, itemIds: selectionMode.selectionState.selectedItems.map(\.id))
    }

    func onLabelsSelected(labelIds: Set<ID>, alsoArchive: Bool) {
        let selectedItemIds = selectionMode.selectionState.selectedItems.map(\.id)
        actionApplyLabels(labelIds, to: selectedItemIds)
        if alsoArchive {
            actionMoveTo(systemFolder: .archive, ids: selectedItemIds)
        }
    }

    func onFolderSelected(labelId: ID) {
        actionMoveTo(labelId: labelId, ids: selectionMode.selectionState.selectedItems.map(\.id))
    }
}

extension MailboxModel {

    struct State {
        var mailboxTitle: LocalizedStringResource = "".notLocalized.stringResource
        var showActionBar: Bool = false
        var unreadItemsCount: UInt64 = 0
        var isUnreadSelected: Bool = false

        // Navigation properties
        var attachmentPresented: AttachmentViewConfig?
        var navigationPath: NavigationPath = .init()
    }
}

extension MailboxModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}
