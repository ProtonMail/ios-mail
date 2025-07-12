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
import InboxCore
import InboxCoreUI
import Foundation
import SwiftUI
import proton_app_uniffi
import ProtonCoreUtilities
import class UIKit.UIImage

/**
 Source of truth for the Mailbox view showing mailbox items (conversations or messages).
 */
final class MailboxModel: ObservableObject {
    @Published var state: State = .init()
    @Published var toast: Toast?
    @Published var emptyFolderBanner: EmptyFolderBanner?
    let selectionMode: SelectionMode = .init()
    private(set) var selectedMailbox: SelectedMailbox

    private let mailSettingsLiveQuery: MailSettingLiveQuerying
    @ObservedObject private var appRoute: AppRouteState
    @Published private(set) var mailbox: Mailbox?
    let draftPresenter: DraftPresenter

    private var messageScroller: MessageScroller?
    private var conversationScroller: ConversationScroller?
    lazy var paginatedDataSource = PaginatedListDataSource<MailboxItemCellUIModel>(
        fetchPage: { [unowned self] currentPage, pageSize in
            let result = await fetchNextPageItems(currentPage: currentPage)
            return result
        })
    private var unreadCountLiveQuery: UnreadItemsCountLiveQuery?

    private lazy var scrollerCallback = LiveQueryCallbackWrapper { [weak self] in
        Task {
            AppLogger.log(message: "items scroller callback", category: .mailbox)
            await self?.refreshMailboxItems()
        }
    }

    let dependencies: Dependencies
    private lazy var starActionPerformer = StarActionPerformer(mailUserSession: dependencies.appContext.userSession)
    private var moveToActionPerformer: MoveToActionPerformer?
    private var readActionPerformer: ReadActionPerformer?
    private var cancellables = Set<AnyCancellable>()

    @NestedObservableObject var accountManagerCoordinator: AccountManagerCoordinator

    var viewMode: ViewMode {
        mailbox?.viewMode() ?? .conversations
    }

    var unreadFilter: ReadFilter {
        state.filterBar.isUnreadButtonSelected ? .unread : .all
    }

    var isOutbox: Bool {
        selectedMailbox.systemFolder == .outbox
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

    private var mailboxUpdatingTask: Task<Void, Error>? {
        didSet {
            oldValue?.cancel()
        }
    }

    init(
        mailSettingsLiveQuery: MailSettingLiveQuerying,
        appRoute: AppRouteState,
        draftPresenter: DraftPresenter,
        dependencies: Dependencies = .init()
    ) {
        AppLogger.log(message: "MailboxModel init", category: .mailbox)
        self.mailSettingsLiveQuery = mailSettingsLiveQuery
        self.appRoute = appRoute
        self.draftPresenter = draftPresenter
        self.selectedMailbox = appRoute.route.selectedMailbox
        self.dependencies = dependencies
        self.accountManagerCoordinator = AccountManagerCoordinator(
            appContext: dependencies.appContext.mailSession,
            accountAuthCoordinator: dependencies.appContext.accountAuthCoordinator
        )

        setUpBindings()
    }

    deinit {
        AppLogger.log(message: "MailboxModel deinit", category: .mailbox)
    }

    func onLoad() {
        Task {
            updateMailboxAndScroller()
            await prepareSwipeActions()
        }
    }
}

// MARK: Bindings

extension MailboxModel {

    private func setUpBindings() {
        appRoute
            .onSelectedMailboxChange
            .sink { [weak self] newSelectedMailbox in
                Task {
                    guard let self else { return }
                    self.selectedMailbox = newSelectedMailbox
                    self.updateMailboxAndScroller()
                    await self.prepareSwipeActions()
                }
            }
            .store(in: &cancellables)

        appRoute
            .openedMailboxItem
            .sink { [weak self] openedItem in
                guard let self else { return }

                state.isSearchPresented = false
                replaceCurrentNavigationPath(with: openedItem)
            }
            .store(in: &cancellables)

        Publishers.Merge(
            mailSettingsLiveQuery.settingHasChanged(keyPath: \.swipeLeft),
            mailSettingsLiveQuery.settingHasChanged(keyPath: \.swipeRight)
        )
        .sink { [weak self] _ in
            Task {
                await self?.prepareSwipeActions()
            }
        }
        .store(in: &cancellables)

        mailSettingsLiveQuery
            .viewModeHasChanged
            .sink { [weak self] _ in
                guard let self else { return }
                AppLogger.log(message: "viewMode has changed", category: .mailbox)
                self.updateMailboxAndScroller()
            }
            .store(in: &cancellables)

        observeSelectionChanges()
        exitSelectAllModeWhenNewItemsAreFetched()
    }

    private func replaceCurrentNavigationPath(with openedItem: MailboxMessageSeed) {
        Task {
            if !state.navigationPath.isEmpty {
                state.navigationPath.removeLast(state.navigationPath.count)
                try await Task.sleep(for: .seconds(0.25))
            }

            state.navigationPath.append(openedItem)
        }
    }

    private func observeSelectionChanges() {
        Publishers.CombineLatest(
            selectionMode.selectionState.$selectedItems.removeDuplicates(),
            selectionMode.selectionState.$isSelectAllEnabled.removeDuplicates()
        )
        .sink { [weak self] _ in
            Task {
                await self?.onSelectedItemsChange()
            }
        }
        .store(in: &cancellables)
    }

    private func onSelectedItemsChange() async {
        state.filterBar.visibilityMode = selectionMode.selectionState.hasItems ? .selectionMode : .regular
        state.filterBar.selectAll = selectAllState
        updateMailboxTitle()
        await refreshMailboxItems()
    }

    private func exitSelectAllModeWhenNewItemsAreFetched() {
        paginatedDataSource.$state
            .map(\.currentPage)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.selectionMode.selectionModifier.exitSelectAllMode()
            }
            .store(in: &cancellables)
    }
}

// MARK: Private

extension MailboxModel {

    private func updateMailboxTitle() {
        state.mailboxTitle =
            selectionMode.selectionState.hasItems
            ? selectionMode.selectionState.title
            : selectedMailbox.name
    }

    private func updateMailboxAndScroller(resetUnreadCount: Bool = true, caller: StaticString = #function) {
        mailboxUpdatingTask = Task {
            guard let userSession = dependencies.appContext.sessionState.userSession else { return }
            do {
                updateMailboxTitle()
                if resetUnreadCount {
                    state.filterBar.unreadCount = .unknown
                    unreadCountLiveQuery = nil
                }

                // These disconnects will prevent unrequested scroller callbacks
                // for the previous state. Call them before the Mailbox constructor.
                messageScroller?.handle().disconnect()
                messageScroller = nil
                conversationScroller?.handle().disconnect()
                conversationScroller = nil

                await paginatedDataSource.resetToInitialState()

                let mailbox =
                    selectedMailbox.isInbox
                    ? try await newInboxMailbox(ctx: userSession).get()
                    : try await newMailbox(ctx: userSession, labelId: selectedMailbox.localId).get()
                self.mailbox = mailbox
                self.moveToActionPerformer = .init(mailbox: mailbox, moveToActions: .productionInstance)
                self.readActionPerformer = .init(mailbox: mailbox)
                AppLogger.log(message: "mailbox view mode: \(mailbox.viewMode().description)", category: .mailbox)
                emptyFolderBanner = await emptyFolderBanner(mailbox: mailbox)

                try Task.checkCancellation()

                if mailbox.viewMode() == .messages {
                    let messageScroller = try await scrollMessagesForLabel(
                        session: userSession,
                        labelId: mailbox.labelId(),
                        filter: unreadFilter,
                        callback: scrollerCallback
                    ).get()
                    try Task.checkCancellation()
                    self.messageScroller = messageScroller
                } else {
                    let conversationScroller = try await scrollConversationsForLabel(
                        session: userSession,
                        labelId: mailbox.labelId(),
                        filter: unreadFilter,
                        callback: scrollerCallback
                    ).get()
                    try Task.checkCancellation()
                    self.conversationScroller = conversationScroller
                }
                await paginatedDataSource.fetchInitialPage()

                unreadCountLiveQuery = UnreadItemsCountLiveQuery(mailbox: mailbox) { [weak self] unreadCount in
                    AppLogger.log(message: "unread count callback: \(unreadCount)", category: .mailbox)
                    await MainActor.run {
                        self?.state.filterBar.unreadCount = .known(unreadCount: unreadCount)
                    }
                }
                await unreadCountLiveQuery?.setUpLiveQuery()
            } catch is CancellationError {
                ()
            } catch {
                AppLogger.log(error: error, category: .mailbox)
                toast = Toast(
                    title: nil,
                    message: L10n.Mailbox.Error.mailboxErrorMessage.string,
                    button: nil,
                    style: .error,
                    duration: 8.0
                )
            }
        }
    }

    private func emptyFolderBanner(mailbox: Mailbox) async -> EmptyFolderBanner? {
        let userSession = dependencies.appContext.userSession
        let labelID: ID = mailbox.labelId()

        guard let banner = try? await getAutoDeleteBanner(session: userSession, labelId: labelID).get() else {
            return nil
        }

        return .init(folder: .init(labelID: labelID, type: banner.folder), userState: banner.state)
    }

    private func prepareSwipeActions() async {
        guard let userSession = dependencies.appContext.sessionState.userSession else { return }

        switch await assignedSwipeActions(currentFolder: selectedMailbox.localId, session: userSession) {
        case .ok(let actions):
            state.swipeActions = actions
        case .error(let error):
            AppLogger.log(error: error, category: .mailbox)
        }
    }

    private func fetchNextPageItems(currentPage: Int) async -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        guard let viewMode = mailbox?.viewMode() else {
            AppLogger.log(message: "no mailbox found when requesting a page", category: .mailbox, isError: true)
            return .init(newItems: [], isLastPage: true)
        }
        do {
            return try await fetchNextPage(viewMode: viewMode, currentPage: currentPage)
        } catch {
            AppLogger.log(error: error, category: .mailbox)
            if error is MailScrollerError {
                return await handleMailScrollerError(viewMode: viewMode, currentPage: currentPage)
            }
            return nextPageAfterNonRecoverableError(error: error)
        }
    }

    private func fetchNextPage(viewMode: ViewMode, currentPage: Int) async throws -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        let result =
            viewMode == .messages
            ? try await fetchNextPageMessages(currentPage: currentPage)
            : try await fetchNextPageConversations(currentPage: currentPage)
        AppLogger.logTemporarily(message: "page \(currentPage) returned \(result.newItems.count) items, isLastPage: \(result.isLastPage)", category: .mailbox)
        return result
    }

    private func handleMailScrollerError(viewMode: ViewMode, currentPage: Int) async -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        do {
            await refreshMailboxItems()
            return try await fetchNextPage(viewMode: viewMode, currentPage: currentPage)
        } catch {
            return nextPageAfterNonRecoverableError(error: error)
        }
    }

    private func nextPageAfterNonRecoverableError(error: Error) -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        AppLogger.log(error: error, category: .mailbox)
        return .init(newItems: paginatedDataSource.state.items, isLastPage: true)
    }

    private func fetchNextPageMessages(currentPage: Int) async throws -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        guard let messageScroller else {
            AppLogger.log(message: "no scroller found when fetching messages", category: .mailbox, isError: true)
            return .init(newItems: [], isLastPage: true)
        }
        AppLogger.logTemporarily(message: "fetching messages page \(currentPage)", category: .mailbox)

        switch await messageScroller.fetchMore() {
        case .ok(let messages):
            let items = mailboxItems(messages: messages)
            return .init(newItems: items, isLastPage: !messageScroller.hasMore())
        case .error(let error):
            throw error
        }
    }

    private func fetchNextPageConversations(currentPage: Int) async throws -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        guard let conversationScroller else {
            AppLogger.log(message: "no scroller found when fetching conversations", category: .mailbox, isError: true)
            return .init(newItems: [], isLastPage: true)
        }
        AppLogger.logTemporarily(message: "fetching conversations page \(currentPage)", category: .mailbox)

        switch await conversationScroller.fetchMore() {
        case .ok(let conversations):
            let items = mailboxItems(conversations: conversations)
            return .init(newItems: items, isLastPage: !conversationScroller.hasMore())
        case .error(let error):
            throw error
        }
    }

    private func refreshMailboxItems() async {
        if viewMode == .messages {
            await refreshMessage()
        } else {
            await refreshConversations()
        }

        selectionMode.selectionModifier.refreshSelectedItemsStatus(newMailboxItems: paginatedDataSource.state.items)
    }

    private func refreshMessage() async {
        guard let messageScroller else { return }
        switch await messageScroller.allItems() {
        case .ok(let messages):
            let items = mailboxItems(messages: messages)
            AppLogger.logTemporarily(message: "refreshed messages before: \(paginatedDataSource.state.items.count) after: \(items.count)", category: .mailbox)
            await paginatedDataSource.updateItems(items)
        case .error(let error):
            AppLogger.log(error: error, category: .mailbox)
        }
    }

    private func refreshConversations() async {
        guard let conversationScroller else { return }
        switch await conversationScroller.allItems() {
        case .ok(let conversations):
            let items = mailboxItems(conversations: conversations)
            AppLogger.logTemporarily(message: "refreshed conversations before: \(paginatedDataSource.state.items.count) after: \(items.count)", category: .mailbox)
            await paginatedDataSource.updateItems(items)
        case .error(let error):
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
        let uxExpectedDuration = Duration.seconds(1.5)
        try? await Task.sleep(for: uxExpectedDuration)
    }
}

// MARK: Filtering

extension MailboxModel {

    func onUnreadFilterChange() {
        AppLogger.log(message: "unread filter has changed to \(state.filterBar.isUnreadButtonSelected)", category: .mailbox)
        updateMailboxAndScroller(resetUnreadCount: false)
    }
}

// MARK: Compose

extension MailboxModel {

    func createDraft(toastStateStore: ToastStateStore) {
        Task {
            await draftPresenter.openNewDraft(onError: {
                toastStateStore.present(toast: .error(message: $0.localizedDescription))
            })
        }
    }

    private func openDraftMessage(messageId: ID) {
        draftPresenter.openDraft(withId: messageId)
    }
}

// MARK: View actions

extension MailboxModel {

    private func applySelectionStateChangeInstead(mailboxItem: MailboxItemCellUIModel) {
        let isCurrentlySelected = selectionMode.selectionState.selectedItems.contains(mailboxItem.toSelectedItem())
        onMailboxItemSelectionChange(item: mailboxItem, isSelected: !isCurrentlySelected)
    }

    func onMailboxItemTap(item: MailboxItemCellUIModel) {
        guard !selectionMode.selectionState.hasItems else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        guard !item.isDraftMessage else {
            openDraftMessage(messageId: item.id)
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
        guard !isOutbox else { return }
        if isSelected {
            let success = selectionMode.selectionModifier.addMailboxItem(item.toSelectedItem())

            if !success {
                toast = .information(message: L10n.Mailbox.selectionLimitReached.string)
            }
        } else {
            selectionMode.selectionModifier.removeMailboxItem(item.toSelectedItem())
        }
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

    func onMailboxItemAction(_ context: SwipeActionContext, toastStateStore: ToastStateStore) {
        let ids: [ID] = [context.itemID]

        switch context.action {
        case .labelAs:
            state.labelAsSheetPresented = .init(sheetType: .labelAs, ids: ids, type: viewMode.itemType.actionSheetItemType)
        case .moveTo(.moveToUnknownLabel):
            state.moveToSheetPresented = .init(sheetType: .moveTo, ids: ids, type: viewMode.itemType.actionSheetItemType)
        case .toggleRead:
            if context.isItemRead {
                markAsUnread(ids: ids)
            } else {
                markAsRead(ids: ids)
            }
        case .toggleStar:
            if context.isItemStarred {
                actionUnstar(ids: ids)
            } else {
                actionStar(ids: ids)
            }
        case .moveTo(.moveToSystemLabel(_, let systemLabelID)):
            moveTo(systemLabel: systemLabelID, ids: ids, toastStateStore: toastStateStore)
        case .noAction:
            break
        }
    }
}

// MARK: conversation actions

extension MailboxModel {

    private func markAsRead(ids: [ID]) {
        readActionPerformer?.markAsRead(itemsWithIDs: ids, itemType: viewMode.itemType)
    }

    private func markAsUnread(ids: [ID]) {
        readActionPerformer?.markAsUnread(itemsWithIDs: ids, itemType: viewMode.itemType)
    }

    private func actionStar(ids: [ID]) {
        starActionPerformer.star(itemsWithIDs: ids, itemType: viewMode.itemType)
    }

    private func actionUnstar(ids: [ID]) {
        starActionPerformer.unstar(itemsWithIDs: ids, itemType: viewMode.itemType)
    }

    private func moveTo(systemLabel: ID, ids: [ID], toastStateStore: ToastStateStore) {
        Task {
            do {
                try await moveToActionPerformer?.moveTo(
                    destinationID: systemLabel,
                    itemsIDs: ids,
                    itemType: viewMode.itemType
                )
            } catch {
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }
        }
    }
}

// MARK: Select All

extension MailboxModel {

    private var unselectedItems: [MailboxSelectedItem] {
        paginatedDataSource.state.items
            .map { $0.toSelectedItem() }
            .filter { !selectionMode.selectionState.selectedItems.contains($0) }
    }

    private var selectAllState: SelectAllState {
        guard selectionMode.selectionState.canSelectMoreItems else {
            return .selectionLimitReached
        }

        return unselectedItems.isEmpty ? .noMoreItemsToSelect : .canSelectMoreItems
    }

    func onSelectAllTapped() {
        switch selectAllState {
        case .canSelectMoreItems:
            selectionMode.selectionModifier.enterSelectAllMode(selecting: unselectedItems)
        case .noMoreItemsToSelect, .selectionLimitReached:
            selectionMode.selectionModifier.deselectAll(stayingInSelectAllMode: true)
        }
    }
}

extension MailboxModel {

    struct State {
        var mailboxTitle: LocalizedStringResource = "".notLocalized.stringResource
        var filterBar: FilterBarState = .init()

        // Navigation properties
        var attachmentPresented: AttachmentViewConfig?
        var isSearchPresented = false
        var navigationPath: NavigationPath = .init()

        var swipeActions: AssignedSwipeActions = .init(left: .noAction, right: .noAction)

        var labelAsSheetPresented: ActionSheetInput?
        var moveToSheetPresented: ActionSheetInput?
    }
}

extension MailboxModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}

extension MailboxItemCellUIModel {
    func toSelectedItem() -> MailboxSelectedItem {
        .init(id: id, isRead: isRead, isStarred: isStarred)
    }
}
