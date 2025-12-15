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
import InboxCore
import InboxCoreUI
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

@MainActor
final class SearchModel: ObservableObject {
    @Published var state: State = .init()
    let selectionMode: SelectionMode = .init()
    lazy var selectedMailbox: SelectedMailbox = .systemFolder(labelId: mailbox.labelId(), systemFolder: .allMail)

    private(set) var mailbox: Mailbox!
    private var searchScroller: SearchScroller?
    private let loadingBarPresenter: LoadingBarPresenter

    lazy var paginatedDataSource = PaginatedListDataSource<MailboxItemCellUIModel>(
        fetchMore: { [weak self] isFirstPage in self?.fetchNextPage(isFirstPage: isFirstPage) }
    )

    private let dependencies: Dependencies
    private lazy var starActionPerformer = StarActionPerformer(mailUserSession: dependencies.appContext.userSession)
    private var cancellables: Set<AnyCancellable> = .init()
    private let mailSettingsLiveQuery: MailSettingLiveQuerying
    private var swipeActionsHandler: SwipeActionsHandler?

    init(
        searchScroller: SearchScroller? = nil,
        dependencies: Dependencies = .init(),
        loadingBarPresenter: LoadingBarPresenter,
        mailSettingsLiveQuery: MailSettingLiveQuerying
    ) {
        AppLogger.logTemporarily(message: "SearchModel init", category: .search)
        self.searchScroller = searchScroller
        self.dependencies = dependencies
        self.loadingBarPresenter = loadingBarPresenter
        self.mailSettingsLiveQuery = mailSettingsLiveQuery
        setUpBindings()
        initialiseMailbox()
    }

    deinit {
        AppLogger.logTemporarily(message: "SearchModel deinit", category: .search)
    }

    private func setUpBindings() {
        selectionMode
            .selectionState
            .$selectedItems
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.updateSelectionStateInDataSource(selectedItems: items)
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
    }

    private func initialiseMailbox() {
        Task {
            let userSession = dependencies.appContext.userSession
            switch newAllMailMailbox(ctx: userSession) {
            case .ok(let mailbox):
                self.mailbox = mailbox
                self.swipeActionsHandler = .init(userSession: userSession, mailbox: mailbox)
            case .error(let error):
                AppLogger.log(error: error, category: .search)
            }
        }
    }

    private func updateSelectionStateInDataSource(selectedItems: Set<MailboxSelectedItem>) {
        let selectedIds = selectedItems.map(\.id)
        let items = paginatedDataSource.state.items

        for index in items.indices {
            let isCurrentlySelected = items[index].isSelected
            let shouldBeSelected = selectedIds.contains(items[index].id)

            if isCurrentlySelected != shouldBeSelected {
                items[index].isSelected = shouldBeSelected
            }
        }
    }

    func searchText(_ text: String) {
        Task {
            let query = text.withoutWhitespace
            guard let searchScroller else {
                await initializeScroller(query: query)
                return
            }
            do {
                paginatedDataSource.resetToInitialState()
                try searchScroller.changeKeywords(keywords: .init(keywords: query)).get()
            } catch {
                AppLogger.log(error: error, category: .search)
            }
        }
    }

    private func initializeScroller(query: String) async {
        let result = await scrollerSearch(
            mailbox: mailbox,
            options: .init(keywords: query),
            callback: MessageScrollerLiveQueryCallbackWrapper { [weak self] update in
                Task {
                    await self?.handleSearchScroller(update: update)
                    await self?.updateSelectedMailboxIfNeeded()
                }
            }
        )

        switch result {
        case .ok(let searchScroller):
            self.searchScroller = searchScroller
            paginatedDataSource.fetchInitialPage()
            await setUpSpamTrashToggleVisibility()
        case .error(let error):
            AppLogger.log(error: error, category: .search)
        }
    }

    func includeTrashSpamTapped() {
        guard let searchScroller else { return }
        do {
            let newSpamTrashToggleState = state.spamTrashToggleState.toggled()
            _ = try searchScroller.changeInclude(include: newSpamTrashToggleState.includeSpamTrash).get()
            state.spamTrashToggleState = newSpamTrashToggleState
        } catch {
            AppLogger.log(error: error, category: .search)
        }
    }

    /// Ensures `selectedMailbox` points to the correct system mailbox
    /// based on the current **Include Spam/Trash** toggle.
    ///
    /// Although the `Mailbox`'s `labelId` is now constant, the underlying mailbox it
    /// represents can still differ depending on whether spam and trash are included.
    /// When this toggle changes, we determine the appropriate system label and labelId
    /// (`.allMail` or `.almostAllMail`) and update the selection accordingly.
    private func updateSelectedMailboxIfNeeded() async {
        guard
            let systemFolder = selectedMailbox.systemFolder,
            [SystemLabel.allMail, .almostAllMail].contains(systemFolder),
            case let systemLabel = state.spamTrashToggleState.systemLabel,
            let userSession = dependencies.appContext.sessionState.userSession,
            let labelId = try? await resolveSystemLabelId(ctx: userSession, label: systemLabel).get()
        else {
            return
        }

        selectedMailbox = .systemFolder(labelId: labelId, systemFolder: systemLabel)
    }

    private func setUpSpamTrashToggleVisibility() async {
        guard let searchScroller else { return }
        do {
            let supportsIncludeFilter = try await searchScroller.supportsIncludeFilter().get()
            let spamTrashToggleState: SpamTrashToggleState
            if supportsIncludeFilter {
                spamTrashToggleState = .visible(isSelected: state.spamTrashToggleState.isSelected)
            } else {
                spamTrashToggleState = .hidden
            }
            state.spamTrashToggleState = spamTrashToggleState
        } catch {
            AppLogger.log(error: error, category: .search)
        }
    }

    private func fetchNextPage(isFirstPage: Bool) {
        AppLogger.log(message: "search fetchMore: isFirstPage \(isFirstPage)", category: .mailbox)
        let result = searchScroller?.fetchMore()
        if case .error(let mailScrollerError) = result {
            AppLogger.log(message: "Error calling fetchMore: \(mailScrollerError)", category: .mailbox, isError: true)
        }
    }

    private func searchScrollerHasMore() async -> Bool {
        guard let searchScroller else { return false }
        switch await searchScroller.hasMore() {
        case .ok(let value):
            return value
        case .error(let error):
            AppLogger.log(message: "Error calling hasMore: \(error)", category: .mailbox, isError: true)
            return false
        }
    }

    private func handleSearchScroller(update: MessageScrollerUpdate) async {
        switch update {
        case .list(let listUpdate):
            await handleMessagesList(update: listUpdate)
        case .status(let statusUpdate):
            switch statusUpdate {
            case .fetchNewStart:
                loadingBarPresenter.show()
            case .fetchNewEnd:
                loadingBarPresenter.hide()
            }
        case .error(let error):
            AppLogger.log(error: error, category: .mailbox)
            let isLastPage = await !searchScrollerHasMore()
            paginatedDataSource.handle(update: .init(isLastPage: isLastPage, value: .error(error), completion: nil))
        }
    }

    private func handleMessagesList(update: MessageScrollerListUpdate) async {
        let isLastPage = await !searchScrollerHasMore()
        let updateType: PaginatedListUpdateType<MailboxItemCellUIModel>
        var completion: (() -> Void)? = nil
        switch update {
        case .none:
            updateType = .none
        case .append(let messages):
            let items = await mailboxItems(messages: messages)
            updateType = .append(items: items)
        case .replaceRange(let from, let to, let messages):
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
        }
        paginatedDataSource.handle(update: .init(isLastPage: isLastPage, value: updateType, completion: completion))
    }

    private func updateSelectedItemsAfterDestructiveUpdate() {
        selectionMode.selectionModifier.refreshSelectedItemsStatus(newMailboxItems: paginatedDataSource.state.items)
    }

    private func mailboxItems(messages: [Message]) async -> [MailboxItemCellUIModel] {
        let selectedIds = Set(selectionMode.selectionState.selectedItems.map(\.id))
        return await Task(priority: .userInitiated) {
            messages.map { message in
                message.toMailboxItemCellUIModel(
                    selectedIds: selectedIds,
                    displaySenderEmail: true,
                    showLocation: true
                )
            }
        }
        .value
    }

    func prepareSwipeActions() async {
        guard let userSession = dependencies.appContext.sessionState.userSession else { return }

        switch await assignedSwipeActions(currentFolder: selectedMailbox.localId, session: userSession) {
        case .ok(let actions):
            state.swipeActions = actions
        case .error(let error):
            AppLogger.log(error: error, category: .mailbox)
        }
    }

    func onMailboxItemAction(_ context: SwipeActionContext, toastStateStore: ToastStateStore) {
        guard let output = swipeActionsHandler?.handle(context, toastStateStore: toastStateStore, viewMode: .messages) else {
            return
        }

        switch output.sheetType {
        case .labelAs:
            state.labelAsSheetPresented = output
        case .moveTo:
            state.moveToSheetPresented = output
        }
    }
}

// MARK: View actions

extension SearchModel {
    private func applySelectionStateChangeInstead(mailboxItem: MailboxItemCellUIModel) {
        let isCurrentlySelected = selectionMode.selectionState.selectedItems.contains(mailboxItem.toSelectedItem())
        onMailboxItemSelectionChange(item: mailboxItem, isSelected: !isCurrentlySelected)
    }

    func onMailboxItemTap(item: MailboxItemCellUIModel, draftPresenter: DraftPresenter) {
        guard !selectionMode.selectionState.hasItems else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        if item.isDraftMessage {
            draftPresenter.openDraft(withId: item.id)
        } else {
            state.navigationPath.append(item)
        }
    }

    func onLongPress(mailboxItem: MailboxItemCellUIModel) {
        guard !selectionMode.selectionState.hasItems else { return }
        onMailboxItemSelectionChange(item: mailboxItem, isSelected: true)
    }

    func onMailboxItemSelectionChange(item: MailboxItemCellUIModel, isSelected: Bool) {
        let selectedItem = item.toSelectedItem()
        if isSelected {
            selectionMode.selectionModifier.addMailboxItem(selectedItem)
        } else {
            selectionMode.selectionModifier.removeMailboxItem(selectedItem)
        }
    }

    func onMailboxItemStarChange(item: MailboxItemCellUIModel, isStarred: Bool) {
        guard !selectionMode.selectionState.hasItems else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }

        let action = isStarred ? starActionPerformer.star : starActionPerformer.unstar
        action([item.id], .message)
    }

    func onMailboxItemAttachmentTap(attachmentId: ID, for item: MailboxItemCellUIModel) {
        guard !selectionMode.selectionState.hasItems, let mailbox else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        state.attachmentPresented = AttachmentViewConfig(id: attachmentId, mailbox: mailbox)
    }
}

// MARK: Swipe between conversations

extension SearchModel {
    func mailboxCursor(startingAt id: ID) async -> MailboxCursorProtocol? {
        do {
            return try await searchScroller?.cursor(lookingAt: id).get()
        } catch {
            AppLogger.log(error: error, category: .mailbox)
            return nil
        }
    }
}

extension SearchModel {
    struct State {
        var attachmentPresented: AttachmentViewConfig?
        var navigationPath: NavigationPath = .init()
        var spamTrashToggleState: SpamTrashToggleState = .hidden
        var swipeActions: AssignedSwipeActions = .init(left: .noAction, right: .noAction)
        var labelAsSheetPresented: ActionSheetInput?
        var moveToSheetPresented: ActionSheetInput?
    }
}

extension SearchModel {
    struct Dependencies: Sendable {
        let appContext: AppContext = .shared
    }
}
