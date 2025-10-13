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
import InboxCore
import proton_app_uniffi
import SwiftUI

@MainActor
final class SearchModel: ObservableObject, @unchecked Sendable {
    @Published var state: State = .init()
    let selectionMode: SelectionMode = .init()
    var selectedMailbox: SelectedMailbox {
        .systemFolder(labelId: mailbox.labelId(), systemFolder: .allMail)
    }

    private(set) var mailbox: Mailbox!
    private var searchScroller: SearchScroller?

    private let listUpdateSubject: PassthroughSubject<PaginatedListUpdate<MailboxItemCellUIModel>, Never> = .init()
    lazy var paginatedDataSource = PaginatedListDataSource<MailboxItemCellUIModel>(
        paginatedListProvider: .init(
            updatePublisher: listUpdateSubject.eraseToAnyPublisher(),
            fetchMore: { [weak self] isFirstPage in self?.fetchNextPage(isFirstPage: isFirstPage) }
        )
    )

    private let dependencies: Dependencies
    private lazy var starActionPerformer = StarActionPerformer(mailUserSession: dependencies.appContext.userSession)
    private var cancellables: Set<AnyCancellable> = .init()

    init(searchScroller: SearchScroller? = nil, dependencies: Dependencies = .init()) {
        AppLogger.logTemporarily(message: "SearchModel init", category: .search)
        self.searchScroller = searchScroller
        self.dependencies = dependencies
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
    }

    private func initialiseMailbox() {
        Task {
            switch newAllMailMailbox(ctx: dependencies.appContext.userSession) {
            case .ok(let mailbox):
                self.mailbox = mailbox
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
            searchScroller?.handle().disconnect()
            searchScroller?.terminate()
            paginatedDataSource.resetToInitialState()

            let result = await scrollerSearch(
                session: dependencies.appContext.userSession,
                options: .init(keywords: query),
                include: .default,
                callback: MessageScrollerLiveQueryCallbackkWrapper { [weak self] update in
                    Task {
                        await self?.handleMessagesUpdate(update)
                    }
                }
            )

            switch result {
            case .ok(let searchScroller):
                self.searchScroller = searchScroller
                paginatedDataSource.fetchInitialPage()
            case .error(let error):
                AppLogger.log(error: error, category: .search)
            }
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

    private func handleMessagesUpdate(_ update: MessageScrollerUpdate) async {
        let isLastPage = await !searchScrollerHasMore()
        let updateType: PaginatedListUpdateType<MailboxItemCellUIModel>
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
            updateType = .error(error)
        }
        listUpdateSubject.send(.init(isLastPage: isLastPage, value: updateType, completion: completion))
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
        }.value
    }
}

// MARK: View actions

extension SearchModel {

    @MainActor
    private func applySelectionStateChangeInstead(mailboxItem: MailboxItemCellUIModel) {
        let isCurrentlySelected = selectionMode.selectionState.selectedItems.contains(mailboxItem.toSelectedItem())
        onMailboxItemSelectionChange(item: mailboxItem, isSelected: !isCurrentlySelected)
    }

    @MainActor
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

    @MainActor
    func onLongPress(mailboxItem: MailboxItemCellUIModel) {
        guard !selectionMode.selectionState.hasItems else { return }
        onMailboxItemSelectionChange(item: mailboxItem, isSelected: true)
    }

    @MainActor
    func onMailboxItemSelectionChange(item: MailboxItemCellUIModel, isSelected: Bool) {
        let selectedItem = item.toSelectedItem()
        if isSelected {
            selectionMode.selectionModifier.addMailboxItem(selectedItem)
        } else {
            selectionMode.selectionModifier.removeMailboxItem(selectedItem)
        }
    }

    @MainActor
    func onMailboxItemStarChange(item: MailboxItemCellUIModel, isStarred: Bool) {
        guard !selectionMode.selectionState.hasItems else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }

        let action = isStarred ? starActionPerformer.star : starActionPerformer.unstar
        action([item.id], .message, nil)
    }

    @MainActor
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
    func mailboxCursor(uiModel: MailboxItemCellUIModel) -> MailboxCursor {
        let index = paginatedDataSource.state.items.firstIndex(of: uiModel) ?? 0
        return searchScroller!.cursor(index: UInt64(index))
    }
}

extension SearchModel {

    struct State {
        var attachmentPresented: AttachmentViewConfig?
        var navigationPath: NavigationPath = .init()
    }
}

extension SearchModel {

    struct Dependencies: Sendable {
        let appContext: AppContext = .shared
    }
}
