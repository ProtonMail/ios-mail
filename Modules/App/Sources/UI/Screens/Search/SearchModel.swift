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

final class SearchModel: ObservableObject, @unchecked Sendable {
    @Published var state: State = .init()
    let selectionMode: SelectionMode = .init()
    var selectedMailbox: SelectedMailbox {
        .systemFolder(labelId: mailbox.labelId(), systemFolder: .allMail)
    }

    private(set) var mailbox: Mailbox!
    private var searchScroller: SearchScroller?

    private lazy var scrollerCallback = LiveQueryCallbackWrapper { [weak self] in
        guard let self else { return }
        Task {
            AppLogger.log(message: "search scroller callback", category: .search)
            await self.refreshMailboxItems()
        }
    }

    lazy var paginatedDataSource = PaginatedListDataSource<MailboxItemCellUIModel>(
        fetchPage: { [unowned self] currentPage, _ in
            let result = await fetchNextPage(currentPage: currentPage)
            return result
        })

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
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    await self.refreshMailboxItems()
                }
            }
            .store(in: &cancellables)
    }

    private func initialiseMailbox() {
        Task {
            switch await newAllMailMailbox(ctx: dependencies.appContext.userSession) {
            case .ok(let mailbox):
                self.mailbox = mailbox
            case .error(let error):
                AppLogger.log(error: error, category: .search)
            }
        }
    }

    func searchText(_ text: String) {
        Task {
            let query = text.withoutWhitespace
            searchScroller?.handle().disconnect()
            await paginatedDataSource.resetToInitialState()

            let result = await scrollerSearch(
                session: dependencies.appContext.userSession,
                options: .init(keywords: query),
                callback: scrollerCallback
            )

            switch result {
            case .ok(let searchScroller):
                self.searchScroller = searchScroller
                await paginatedDataSource.fetchInitialPage()
            case .error(let error):
                AppLogger.log(error: error, category: .search)
            }
        }
    }

    private func fetchNextPage(currentPage: Int) async -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        let searchScroller = searchScroller.unsafelyUnwrapped
        do {
            return try await fetchMore(searchScroller: searchScroller, currentPage: currentPage)
        } catch {
            AppLogger.log(error: error, category: .search)
            if error is MailScrollerError {
                return await handleMailScrollerError(searchScroller: searchScroller, currentPage: currentPage)
            }
            return nextPageAfterNonRecoverableError(error: error)
        }
    }

    private func fetchMore(searchScroller: SearchScroller, currentPage: Int) async throws -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        switch await searchScroller.fetchMore() {
        case .ok(let messages):
            let result = PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult(
                newItems: mailboxItems(messages: messages),
                isLastPage: !searchScroller.hasMore()
            )
            AppLogger.log(message: "page \(currentPage) returned \(result.newItems.count) items, isLastPage: \(result.isLastPage)", category: .search)
            return result
        case .error(let error):
            throw error
        }
    }

    private func handleMailScrollerError(searchScroller: SearchScroller, currentPage: Int) async -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        do {
            await refreshMailboxItems()
            return try await fetchMore(searchScroller: searchScroller, currentPage: currentPage)
        } catch {
            return nextPageAfterNonRecoverableError(error: error)
        }
    }

    private func nextPageAfterNonRecoverableError(error: Error) -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        AppLogger.log(error: error, category: .search)
        return .init(newItems: paginatedDataSource.state.items, isLastPage: true)
    }

    private func mailboxItems(messages: [Message]) -> [MailboxItemCellUIModel] {
        let selectedIds = Set(selectionMode.selectionState.selectedItems.map(\.id))
        return messages.map { message in
            message.toMailboxItemCellUIModel(
                selectedIds: selectedIds,
                displaySenderEmail: true,
                showLocation: true
            )
        }
    }

    private func refreshMailboxItems() async {
        guard let searchScroller else { return }
        switch await searchScroller.allItems() {
        case .ok(let messages):
            let items = mailboxItems(messages: messages)
            AppLogger.log(message: "refreshed results before: \(paginatedDataSource.state.items.count) after: \(items.count)", category: .search)
            await paginatedDataSource.updateItems(items)

            await selectionMode.selectionModifier.refreshSelectedItemsStatus(newMailboxItems: paginatedDataSource.state.items)
        case .error(let error):
            AppLogger.log(error: error, category: .search)
        }
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
        let modifier = selectionMode.selectionModifier
        let action = isSelected ? modifier.addMailboxItem : modifier.removeMailboxItem
        action(item.toSelectedItem())
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
