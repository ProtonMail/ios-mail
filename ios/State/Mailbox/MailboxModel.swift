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

import Combine
import Foundation
import SwiftUI
import proton_app_uniffi
import class UIKit.UIImage

/**
 Source of truth for the Mailbox view showing mailbox items (conversations or messages).
 */
final class MailboxModel: ObservableObject {
    @ObservedObject private var appRoute: AppRouteState
    @Published private(set) var mailboxTitle: LocalizedStringResource = .init(stringLiteral: "")

    // Filter
    @Published var unreadItemsCount: UInt64 = 0
    @Published var isUnreadSelected: Bool = false

    // Navigation properties
    @Published var attachmentPresented: AttachmentViewConfig?
    @Published var navigationPath: NavigationPath = .init()

    let selectionMode: SelectionModeState

    var viewMode: ViewMode {
        mailbox?.viewMode() ?? .conversations
    }

    private let pageSize: Int64 = 50
    private let mailSettingsLiveQuery: MailSettingLiveQuerying
    private(set) var selectedMailbox: SelectedMailbox
    private var mailbox: Mailbox?
    private let dependencies: Dependencies
    private var cancellables = Set<AnyCancellable>()

    private var messagePaginator: MessagePaginator?
    private var conversationPaginator: ConversationPaginator?
    lazy var paginatedDatasource = PaginatedListDatasource<MailboxItemCellUIModel>(fetchPage: { currentPage, pageSize in
        let result = await self.fetchNextPageItems(currentPage: currentPage)
        return result
    })

    private var unreadCountLiveQuery: UnreadItemsCountLiveQuery?
//    private let itemListCallback: LiveQueryCallbackWrapper = .init()
//    private var itemListHandle: WatchHandle?

    private var userSession: MailUserSession {
        dependencies.appContext.userSession
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
        self.selectionMode = SelectionModeState()
        self.dependencies = dependencies

        setUpBindings()
//        setUpCallbacks()

        if let openedItem = openedItem {
            navigationPath.append(openedItem)
        }
    }

    deinit {
        AppLogger.log(message: "MailboxModel deinit", category: .mailbox)
    }

    func onViewDidAppear() async {
//        await updateMailboxAndFetchData()
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
//                    await self.updateMailboxAndFetchData()
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
//                    await self.updateMailboxAndFetchData()
                    await self.updateMailboxAndPaginator()
                }
            }
            .store(in: &cancellables)

        selectionMode
            .$hasSelectedItems
            .sink { [weak self] hasItems in
                Task {
//                    await self?.readMailboxItems()
                    await self?.refreshMailboxItems()
                }
            }
            .store(in: &cancellables)
    }

//    private func setUpCallbacks() {
//        itemListCallback.delegate = { [weak self] in
//            Task {
//                AppLogger.logTemporarily(message: "item list callback", category: .mailbox)
////                await self?.readMailboxItems()
//            }
//        }
//    }

    /// Call this function to reset the Mailbox object with a new label id and fetch its mailbox items
//    private func updateMailboxAndFetchData() async {
//        await updateState(.loading)
//        guard let userSession = dependencies.appContext.activeUserSession else { return }
//        do {
//            let mailbox = selectedMailbox.isInbox
//            ? try await Mailbox.inbox(ctx: userSession)
//            : try await Mailbox(ctx: userSession, labelId: selectedMailbox.localId)
//            self.mailbox = mailbox
//
//            AppLogger.log(message: "mailbox view mode: \(mailbox.viewMode().description)", category: .mailbox)
//            await createWatchHandlers(for: mailbox)
//
//            // temporary, delete when the handler callback is triggered when initialised
//            await readMailboxItems()
//        } catch {
//            AppLogger.log(error: error, category: .mailbox)
//        }
//    }

    /// Keeps a reference to the `WatchHandler` objects responsible for calling back when there are data changes
//    private func createWatchHandlers(for mailbox: Mailbox) async {
//        unreadCountLiveQuery = UnreadItemsCountLiveQuery(mailbox: mailbox) { [weak self] unreadCount in
//            await MainActor.run {
//                self?.unreadItemsCount = unreadCount
//            }
//        }
//        await unreadCountLiveQuery?.setUpLiveQuery()
//
//        do {
//            switch viewMode {
//            case .conversations:
//                itemListHandle = try await watchConversationsForLabel(
//                    session: userSession,
//                    labelId: mailbox.labelId(),
//                    callback: itemListCallback
//                ).handle
//            case .messages:
//                itemListHandle = try await watchMessagesForLabel(
//                    session: userSession,
//                    labelId: mailbox.labelId(),
//                    callback: itemListCallback
//                ).handle
//            }
//        } catch {
//            AppLogger.log(error: error, category: .mailbox)
//        }
//    }

//    private func readMailboxItems() async {
//        guard let mailbox else {
//            AppLogger.log(message: "No mailbox object found", category: .mailbox, isError: true)
//            return
//        }
//        let selectedIds = Set(selectionMode.selectedItems.map(\.id))
//        var mailboxItems = [MailboxItemCellUIModel]()
//        do {
//            switch viewMode {
//            case .conversations:
//                mailboxItems = try await conversationsForLabel(session: userSession, labelId: mailbox.labelId())
//                    .map { conversation in
//                        conversation.toMailboxItemCellUIModel(selectedIds: selectedIds)
//                    }
//
//            case .messages:
//                let systemFolder = selectedMailbox.systemFolder
//                mailboxItems = try await messagesForLabel(session: userSession, labelId: mailbox.labelId())
//                    .map { message in
//                        let displaySenderEmail = ![SystemFolderLabel.drafts, .allDrafts, .sent, .allSent, .scheduled]
//                            .contains(systemFolder)
//                        return message.toMailboxItemCellUIModel(
//                            selectedIds: selectedIds,
//                            displaySenderEmail: displaySenderEmail
//                        )
//                    }
//            }
//        }
//        catch {
//            AppLogger.log(error: error, category: .mailbox)
//        }
//        let newState: State = mailboxItems.count > 0 ? .data(mailboxItems) : .empty
//        await updateState(newState)
//
//        selectionMode.refreshSelectedItemsStatus { itemIds in
//            guard !itemIds.isEmpty, paginatedDatasource.state == .data else { return [] }
//            let selectedItems = mailboxItems
//                .filter { itemIds.contains($0.id) }
//                .map { $0.toSelectedItem() }
//            return Set(selectedItems)
//        }
//    }

    private func updateMailboxAndPaginator() async {
        guard let userSession = dependencies.appContext.activeUserSession else { return }
        do {
            let mailbox = selectedMailbox.isInbox
            ? try await Mailbox.inbox(ctx: userSession)
            : try await Mailbox(ctx: userSession, labelId: selectedMailbox.localId)
            self.mailbox = mailbox
            AppLogger.log(message: "mailbox view mode: \(mailbox.viewMode().description)", category: .mailbox)

            if mailbox.viewMode() == .messages {
                messagePaginator = try await paginateMessagesForLabel(
                    session: userSession,
                    labelId: mailbox.labelId(),
                    callback: self
                )
            } else {
                conversationPaginator = try await paginateConversationsForLabel(
                    session: userSession,
                    labelId: mailbox.labelId(),
                    callback: self
                )
            }
            unreadCountLiveQuery = UnreadItemsCountLiveQuery(mailbox: mailbox) { [weak self] unreadCount in
                AppLogger.log(message: "unread count callback: \(unreadCount)", category: .mailbox)
                await MainActor.run {
                    self?.unreadItemsCount = unreadCount
                }
            }
            await unreadCountLiveQuery?.setUpLiveQuery()

            updateMailboxTitle()
            
            await paginatedDatasource.fetchInitialPage()

        } catch {
            AppLogger.log(error: error, category: .mailbox)
            fatalError("failed to instantiate the Mailbox or Paginator object")
        }
    }

    private func fetchNextPageItems(currentPage: Int) async -> PaginatedListDatasource<MailboxItemCellUIModel>.NextPageResult {
        guard let mailbox else {
            AppLogger.log(message: "no mailbox found when requesting a page", isError: true)
            return .init(newItems: [], isLastPage: true)
        }
        do {
            let result: PaginatedListDatasource<MailboxItemCellUIModel>.NextPageResult
            result = mailbox.viewMode() == .messages
            ? try await fetchNextPageMessages(currentPage: currentPage)
            : try await fetchNextPageConversations(currentPage: currentPage)
            AppLogger.log(message: "page \(currentPage) returned \(result.newItems.count) items", category: .mailbox)
            return result
        } catch {
            AppLogger.log(error: error, category: .mailbox)
            return .init(newItems: paginatedDatasource.state.items, isLastPage: true)
        }
    }

    private func fetchNextPageMessages(currentPage: Int) async throws -> PaginatedListDatasource<MailboxItemCellUIModel>.NextPageResult {
        let selectedIds = Set(selectionMode.selectedItems.map(\.id))
        guard let messagePaginator else {
            AppLogger.log(message: "no paginator found when fetching messages", category: .mailbox, isError: true)
            return .init(newItems: [], isLastPage: true)
        }
        let systemFolder = selectedMailbox.systemFolder
        let displaySenderEmail = ![SystemFolderLabel.drafts, .allDrafts, .sent, .allSent, .scheduled]
            .contains(systemFolder)
        AppLogger.log(message: "fetching messages page \(currentPage)", category: .mailbox)

        let messages = currentPage == 0
        ? try await messagePaginator.currentPage()
        : try await messagePaginator.nextPage()
        let items = messages.map {
            $0.toMailboxItemCellUIModel(selectedIds: selectedIds, displaySenderEmail: displaySenderEmail)
        }

        logPaginatorState(messagePaginator, items: items)

        return .init(newItems: items, isLastPage: !messagePaginator.hasNextPage())
    }

    private func fetchNextPageConversations(currentPage: Int) async throws -> PaginatedListDatasource<MailboxItemCellUIModel>.NextPageResult {
        let selectedIds = Set(selectionMode.selectedItems.map(\.id))
        guard let conversationPaginator else {
            AppLogger.log(message: "no paginator found when fetching conversations", category: .mailbox, isError: true)
            return .init(newItems: [], isLastPage: true)
        }
        AppLogger.log(message: "fetching conversations page \(currentPage)", category: .mailbox)

        let messages = currentPage == 0
        ? try await conversationPaginator.currentPage()
        : try await conversationPaginator.nextPage()
        let items = messages.map {
            $0.toMailboxItemCellUIModel(selectedIds: selectedIds)
        }

        logPaginatorState(conversationPaginator, items: items)

        return .init(newItems: items, isLastPage: !conversationPaginator.hasNextPage())
    }

    private func logPaginatorState(_ paginator: MessagePaginator, items: [MailboxItemCellUIModel]) {
        print("👉 \(items.count) items from new page | first item: '\(items.first?.subject ?? "")'")
        print(" paginator state: currentPageNumber = \(paginator.currentPageNumber()) resultCount = \(paginator.resultCount()) pageCount = \(paginator.pageCount()) hasNextPage() = \(paginator.hasNextPage())")
    }

    private func logPaginatorState(_ paginator: ConversationPaginator, items: [MailboxItemCellUIModel]) {
        print("👉 \(items.count) items from new page | first item: '\(items.first?.subject ?? "")'")
        print(" paginator state: currentPageNumber = \(paginator.currentPageNumber()) resultCount = \(paginator.resultCount()) pageCount = \(paginator.pageCount()) hasNextPage() = \(paginator.hasNextPage())")
    }

    private func refreshMailboxItems() async {
        if viewMode == .messages {
            await refreshMessage()
        } else {
            await refreshConversations()
        }

        selectionMode.refreshSelectedItemsStatus { itemIds in
            let selectedItems = paginatedDatasource.state.items
                .filter { itemIds.contains($0.id) }
                .map { $0.toSelectedItem() }
            return Set(selectedItems)
        }
    }

    private func refreshMessage() async {
        guard let messagePaginator else { return }
        let selectedIds = Set(selectionMode.selectedItems.map(\.id))
        let systemFolder = selectedMailbox.systemFolder
        let displaySenderEmail = ![SystemFolderLabel.drafts, .allDrafts, .sent, .allSent, .scheduled]
            .contains(systemFolder)
        do {
            let messages = try await messagePaginator.reload()
            let items = messages.map {
                $0.toMailboxItemCellUIModel(selectedIds: selectedIds, displaySenderEmail: displaySenderEmail)
            }
            AppLogger.log(message: "refreshed messages before: \(paginatedDatasource.state.items.count) after: \(items.count)", category: .mailbox)
            await paginatedDatasource.updateItems(items)
        } catch {
            AppLogger.log(error: error, category: .mailbox)
        }
    }

    private func refreshConversations() async {
        guard let conversationPaginator else { return }
        let selectedIds = Set(selectionMode.selectedItems.map(\.id))
        do {
            let conversations = try await conversationPaginator.reload()
            let items = conversations.map {
                $0.toMailboxItemCellUIModel(selectedIds: selectedIds)
            }
            AppLogger.log(message: "refreshed conversations before: \(paginatedDatasource.state.items.count) after: \(items.count)", category: .mailbox)
            await paginatedDatasource.updateItems(items)
        } catch {
            AppLogger.log(error: error, category: .mailbox)
        }
    }

    private func updateMailboxTitle() {
        let selectionMode = selectionMode
        let hasSelectedItems = selectionMode.hasSelectedItems
        let selectedItemsCount = selectionMode.selectedItems.count
        let selectedMailboxName = selectedMailbox.name

        mailboxTitle = hasSelectedItems ? L10n.Mailbox.selected(emailsCount: selectedItemsCount) : selectedMailboxName
    }
}

// TODO: Make sure there is no retention cycle
extension MailboxModel: LiveQueryCallback {

    func onUpdate() {
        Task { [weak self] in
            AppLogger.log(message: "items paginator callback", category: .mailbox)
            await self?.refreshMailboxItems()
        }
    }
}

// MARK: View actions

extension MailboxModel {

    private func applySelectionStateChangeInstead(mailboxItem: MailboxItemCellUIModel) {
        let isCurrentlySelected = selectionMode.selectedItems.contains(mailboxItem.toSelectedItem())
        onMailboxItemSelectionChange(item: mailboxItem, isSelected: !isCurrentlySelected)
    }

    @MainActor
    func onMailboxItemTap(item: MailboxItemCellUIModel) {
        guard !selectionMode.hasSelectedItems else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        navigationPath.append(item)
    }

    @MainActor
    func onLongPress(mailboxItem: MailboxItemCellUIModel) {
        guard !selectionMode.hasSelectedItems else { return }
        onMailboxItemSelectionChange(item: mailboxItem, isSelected: true)
    }

    @MainActor
    func onMailboxItemSelectionChange(item: MailboxItemCellUIModel, isSelected: Bool) {
        isSelected
        ? selectionMode.addMailboxItem(item.toSelectedItem())
        : selectionMode.removeMailboxItem(item.toSelectedItem())
    }

    func onMailboxItemStarChange(item: MailboxItemCellUIModel, isStarred: Bool) {
        guard !selectionMode.hasSelectedItems else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        isStarred ? actionStar(ids: [item.id]) : actionUnstar(ids: [item.id])
    }

    func onMailboxItemAttachmentTap(attachmentId: ID, for item: MailboxItemCellUIModel) {
        guard !selectionMode.hasSelectedItems, let mailbox else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        attachmentPresented = AttachmentViewConfig(id: attachmentId, mailbox: mailbox)
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
                try await deleteConversations(mailbox: mailbox, ids: ids)
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
        let selectedConversations = paginatedDatasource.state.items.filter({ $0.isSelected })
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
        paginatedDatasource.state.items.filter({ $0.isSelected }).map(\.labelUIModel.allLabelIds)
    }

    func onActionTap(_ action: Action) {
        onMailboxItemAction(action, itemIds: selectionMode.selectedItems.map(\.id))
    }

    func onLabelsSelected(labelIds: Set<ID>, alsoArchive: Bool) {
        let selectedItemIds = selectionMode.selectedItems.map(\.id)
        actionApplyLabels(labelIds, to: selectedItemIds)
        if alsoArchive {
            actionMoveTo(systemFolder: .archive, ids: selectedItemIds)
        }
    }

    func onFolderSelected(labelId: ID) {
        actionMoveTo(labelId: labelId, ids: selectionMode.selectedItems.map(\.id))
    }
}

extension MailboxModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}
