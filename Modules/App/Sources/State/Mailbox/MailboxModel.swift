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
import InboxIAP
import Foundation
import SwiftUI
import proton_app_uniffi
import ProtonCoreUtilities
import class UIKit.UIImage

/**
 Source of truth for the Mailbox view showing mailbox items (conversations or messages).
 */
@MainActor
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
    private let listUpdateSubject: PassthroughSubject<PaginatedListUpdate<MailboxItemCellUIModel>, Never> = .init()
    lazy var paginatedDataSource = PaginatedListDataSource<MailboxItemCellUIModel>(
        paginatedListProvider: .init(
            updatePublisher: listUpdateSubject.eraseToAnyPublisher(),
            fetchMore: { [weak self] isFirstPage in self?.fetchNextPage(isFirstPage: isFirstPage) }
        ),
        id: \.id
    )
    private var unreadCountLiveQuery: UnreadItemsCountLiveQuery?

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
        return ![SystemLabel.drafts, .allDrafts, .sent, .allSent, .scheduled]
            .contains(systemFolder)
    }

    private var itemsShouldShowLocation: Bool {
        let systemFolder = selectedMailbox.systemFolder
        let mailboxOfSpecificSystemFolder = [SystemLabel.allMail, .almostAllMail, .starred].contains(systemFolder)
        return mailboxOfSpecificSystemFolder || selectedMailbox.isCustomLabel
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
        self.selectedMailbox = appRoute.route.selectedMailbox!
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
            await updateMailboxAndScroller()
            await prepareSwipeActions()
        }
    }
}

// MARK: Bindings

extension MailboxModel {

    private func setUpBindings() {
        appRoute.$route.sink { [weak self] route in
            guard let self else { return }

            switch route {
            case .mailbox(selectedMailbox: let newSelectedMailbox):
                guard newSelectedMailbox != selectedMailbox else {
                    return
                }

                Task {
                    self.selectionMode.selectionModifier.exitSelectionMode()
                    self.selectedMailbox = newSelectedMailbox
                    await self.updateMailboxAndScroller()
                    await self.prepareSwipeActions()
                }
            case .mailboxOpenMessage(seed: let openedItem):
                state.isSearchPresented = false
                replaceCurrentNavigationPath(with: openedItem)
            case .composer(let fromShareExtension):
                state.isSearchPresented = false

                if fromShareExtension {
                    openDraftForShareExtension()
                } else {
                    createDraft()
                }
            case .mailto(let mailtoData):
                createDraft(with: mailtoData)
            case .search:
                state.isSearchPresented = true
            }
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
                Task {
                    guard let self else { return }
                    AppLogger.log(message: "viewMode has changed", category: .mailbox)
                    await self.updateMailboxAndScroller()
                }
            }
            .store(in: &cancellables)

        mailSettingsLiveQuery
            .settingHasChanged(keyPath: \.confirmLink, dropFirst: false)
            .sink { [weak self] confirmLink in
                self?.state.confirmLink = confirmLink
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
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.onSelectedItemsChange()
        }
        .store(in: &cancellables)
    }

    private func onSelectedItemsChange() {
        state.filterBar.visibilityMode = selectionMode.selectionState.hasItems ? .selectionMode : .regular
        state.filterBar.selectAll = selectAllState
        updateMailboxTitle()
        updateSelectionStateInDataSource()
    }

    private func updateSelectionStateInDataSource() {
        let selectedIds = Set(selectionMode.selectionState.selectedItems.map(\.id))
        let items = paginatedDataSource.state.items

        for index in items.indices {
            let isCurrentlySelected = items[index].isSelected
            let shouldBeSelected = selectedIds.contains(items[index].id)

            if isCurrentlySelected != shouldBeSelected {
                items[index].isSelected = shouldBeSelected
            }
        }
    }

    private func exitSelectAllModeWhenNewItemsAreFetched() {
        paginatedDataSource.$state
            .map { Set($0.items.map(\.id)) }
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

    private func updateMailboxAndScroller() async {
        guard let userSession = dependencies.appContext.sessionState.userSession else { return }
        do {
            updateMailboxTitle()
            state.filterBar.unreadCount = .unknown
            unreadCountLiveQuery = nil

            // These disconnects will prevent unrequested scroller callbacks
            // for the previous state. Call them before the Mailbox constructor.
            messageScroller?.handle().disconnect()
            messageScroller?.terminate()
            conversationScroller?.handle().disconnect()
            conversationScroller?.terminate()

            paginatedDataSource.resetToInitialState()
            state.filterBar.isUnreadButtonSelected = false

            let mailbox =
                selectedMailbox.isInbox
                ? try newInboxMailbox(ctx: userSession).get()
                : try newMailbox(ctx: userSession, labelId: selectedMailbox.localId).get()
            self.mailbox = mailbox
            self.moveToActionPerformer = .init(mailbox: mailbox, moveToActions: .productionInstance)
            self.readActionPerformer = .init(mailbox: mailbox)
            emptyFolderBanner = await emptyFolderBanner(mailbox: mailbox)

            if mailbox.viewMode() == .messages {
                messageScroller = try await scrollMessagesForLabel(
                    session: userSession,
                    labelId: mailbox.labelId(),
                    unread: unreadFilter,
                    include: .default,
                    callback: MessageScrollerLiveQueryCallbackkWrapper { [weak self] update in
                        Task {
                            await self?.handleMessagesUpdate(update)
                        }
                    }
                ).get()
            } else {
                conversationScroller = try await scrollConversationsForLabel(
                    session: userSession,
                    labelId: mailbox.labelId(),
                    unread: unreadFilter,
                    include: .default,
                    callback: ConversationScrollerLiveQueryCallbackkWrapper { [weak self] update in
                        Task {
                            await self?.handleConversationsUpdate(update)
                        }
                    }
                ).get()
            }
            paginatedDataSource.fetchInitialPage()

            unreadCountLiveQuery = UnreadItemsCountLiveQuery(mailbox: mailbox) { [weak self] unreadCount in
                AppLogger.log(message: "unread count callback: \(unreadCount)", category: .mailbox)
                await MainActor.run {
                    self?.state.filterBar.unreadCount = .known(unreadCount: unreadCount)
                }
            }
            await unreadCountLiveQuery?.setUpLiveQuery()
        } catch {
            AppLogger.log(error: error, category: .mailbox)
            toast = .error(message: L10n.Mailbox.Error.mailboxErrorMessage.string, duration: .long)
        }
    }

    private func conversationScrollerHasMore() async -> Bool {
        guard let conversationScroller else { return false }
        switch await conversationScroller.hasMore() {
        case .ok(let value):
            return value
        case .error(let error):
            AppLogger.log(message: "Error calling hasMore: \(error)", category: .mailbox, isError: true)
            return false
        }
    }

    private func messageScrollerHasMore() async -> Bool {
        guard let messageScroller else { return false }
        switch await messageScroller.hasMore() {
        case .ok(let value):
            return value
        case .error(let error):
            AppLogger.log(message: "Error calling hasMore: \(error)", category: .mailbox, isError: true)
            return false
        }
    }

    private func handleConversationsUpdate(_ update: ConversationScrollerUpdate) async {
        let updateType: PaginatedListUpdateType<MailboxItemCellUIModel>
        let isLastPage = await !conversationScrollerHasMore()
        var completion: (() -> Void)? = nil
        switch update {
        case .none:
            updateType = .none
        case .append(let conversations):
            let items = await mailboxItems(conversations: conversations)
            updateType = .append(items: items)
        case let .replaceRange(from, to, conversations):
            let items = await mailboxItems(conversations: conversations)
            updateType = .replaceRange(from: Int(from), to: Int(to), items: items)
            completion = { [weak self] in self?.updateSelectedItemsAfterDestructiveUpdate() }
        case .replaceFrom(let index, let conversations):
            let items = await mailboxItems(conversations: conversations)
            updateType = .replaceFrom(index: Int(index), items: items)
            completion = { [weak self] in self?.updateSelectedItemsAfterDestructiveUpdate() }
        case .replaceBefore(let index, let conversations):
            let items = await mailboxItems(conversations: conversations)
            updateType = .replaceBefore(index: Int(index), items: items)
            completion = { [weak self] in self?.updateSelectedItemsAfterDestructiveUpdate() }
        case .error(let error):
            AppLogger.log(error: error, category: .mailbox)
            showScrollerErrorIfNotNetwork(error: error)
            updateType = .error(error)
        }
        listUpdateSubject.send(.init(isLastPage: isLastPage, value: updateType, completion: completion))
    }

    private func handleMessagesUpdate(_ update: MessageScrollerUpdate) async {
        let updateType: PaginatedListUpdateType<MailboxItemCellUIModel>
        let isLastPage = await !messageScrollerHasMore()
        var completion: (() -> Void)? = nil
        switch update {
        case .none:
            updateType = .none
        case .append(let messages):
            let items = await mailboxItems(messages: messages)
            updateType = .append(items: items)
        case let .replaceRange(from, to, messages):
            let items = await mailboxItems(messages: messages)
            updateType = .replaceRange(from: Int(from), to: Int(to), items: items)
            completion = { [weak self] in self?.updateSelectedItemsAfterDestructiveUpdate() }
        case .replaceFrom(let index, let messages):
            let items = await mailboxItems(messages: messages)
            updateType = .replaceFrom(index: Int(index), items: items)
            completion = { [weak self] in self?.updateSelectedItemsAfterDestructiveUpdate() }
        case .replaceBefore(let index, let messages):
            let items = await mailboxItems(messages: messages)
            updateType = .replaceBefore(index: Int(index), items: items)
            completion = { [weak self] in self?.updateSelectedItemsAfterDestructiveUpdate() }
        case .error(let error):
            AppLogger.log(error: error, category: .mailbox)
            showScrollerErrorIfNotNetwork(error: error)
            updateType = .error(error)
        }
        listUpdateSubject.send(.init(isLastPage: isLastPage, value: updateType, completion: completion))
    }

    // TODO: Remove once the SDK does not return network as a possible MailScrollerError
    private func showScrollerErrorIfNotNetwork(error: MailScrollerError) {
        if case .other(.network) = error { return }
        toast = .error(message: L10n.Mailbox.Error.issuesLoadingMailboxContent.string, duration: .medium)
    }

    private func updateSelectedItemsAfterDestructiveUpdate() {
        selectionMode.selectionModifier.refreshSelectedItemsStatus(newMailboxItems: paginatedDataSource.state.items)
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

    private func fetchNextPage(isFirstPage: Bool) {
        AppLogger.log(message: "\(viewMode) fetchMore: isFirstPage \(isFirstPage)", category: .mailbox)
        let logError: (MailScrollerError) -> Void = { error in
            AppLogger.log(message: "Error calling fetchMore: \(error)", category: .mailbox, isError: true)
        }
        if viewMode == .conversations {
            let result = conversationScroller?.fetchMore()
            if case .error(let mailScrollerError) = result { logError(mailScrollerError) }
        } else {
            let result = messageScroller?.fetchMore()
            if case .error(let mailScrollerError) = result { logError(mailScrollerError) }
        }
    }

    private func mailboxItems(messages: [Message]) async -> [MailboxItemCellUIModel] {
        let selectedIds = Set(selectionMode.selectionState.selectedItems.map(\.id))
        let displaySenderEmail = messagesShouldDisplaySenderEmail
        let showLocation = itemsShouldShowLocation

        return await Task(priority: .userInitiated) {
            messages.map { message in
                message.toMailboxItemCellUIModel(
                    selectedIds: selectedIds,
                    displaySenderEmail: displaySenderEmail,
                    showLocation: showLocation
                )
            }
        }.value
    }

    private func mailboxItems(conversations: [Conversation]) async -> [MailboxItemCellUIModel] {
        let selectedIds = Set(selectionMode.selectionState.selectedItems.map(\.id))
        let showLocation = itemsShouldShowLocation

        return await Task(priority: .userInitiated) {
            conversations.map { conversation in
                conversation.toMailboxItemCellUIModel(selectedIds: selectedIds, showLocation: showLocation)
            }
        }.value
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
        Task {
            AppLogger.log(message: "unread filter has changed to \(unreadFilter)", category: .mailbox)
            if viewMode == .conversations {
                _ = conversationScroller?.changeFilter(unread: unreadFilter)
            } else {
                _ = messageScroller?.changeFilter(unread: unreadFilter)
            }
        }
    }
}

// MARK: Compose

extension MailboxModel {

    func createDraft() {
        Task {
            await draftPresenter.openNewDraft(onError: {
                toast = .error(message: $0.localizedDescription)
            })
        }
    }

    private func openDraftMessage(messageId: ID) {
        draftPresenter.openDraft(withId: messageId)
    }

    private func createDraft(with mailtoData: MailtoData) {
        Task {
            do {
                try await draftPresenter.openNewDraft(with: mailtoData)
            } catch {
                toast = .error(message: error.localizedDescription)
            }
        }
    }

    private func openDraftForShareExtension() {
        Task {
            do {
                try await draftPresenter.openDraftForShareExtension()
            } catch {
                toast = .error(message: error.localizedDescription)
            }
        }
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
            state.labelAsSheetPresented = .init(sheetType: .labelAs, ids: ids, mailboxItem: viewMode.itemType.mailboxItem)
        case .moveTo(.moveToUnknownLabel):
            state.moveToSheetPresented = .init(sheetType: .moveTo, ids: ids, mailboxItem: viewMode.itemType.mailboxItem)
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
        case .moveTo(.moveToSystemLabel(let label, let labelID)):
            move(itemIDs: ids, to: labelID, label: label, toastStateStore: toastStateStore)
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

    private func move(
        itemIDs: [ID],
        to destinationID: ID,
        label: SystemLabel,
        toastStateStore: ToastStateStore
    ) {
        let userSession = dependencies.appContext.userSession

        Task { [weak self] in
            guard let self else { return }
            do {
                let undo = try await moveToActionPerformer?.moveTo(
                    destinationID: destinationID,
                    itemsIDs: itemIDs,
                    itemType: viewMode.itemType
                )
                let toastID = UUID()
                let undoAction = undo.undoAction(userSession: userSession) {
                    Dispatcher.dispatchOnMain(
                        .init(block: {
                            toastStateStore.dismiss(withID: toastID)
                        }))
                }
                let toast: Toast = .moveTo(
                    id: toastID,
                    destinationName: label.humanReadable.string,
                    undoAction: undoAction
                )
                toastStateStore.present(toast: toast)
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

        var upsellPresented: UpsellScreenModel?
        var onboardingUpsellPresented: OnboardingUpsellScreenModel?

        var confirmLink: Bool = true
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
