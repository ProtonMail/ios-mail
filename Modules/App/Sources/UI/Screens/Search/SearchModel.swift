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
    private var searchPaginator: MessagePaginator?
    private var paginatorCallback: LiveQueryCallbackWrapper = .init()
    lazy var paginatedDataSource = PaginatedListDataSource<MailboxItemCellUIModel>(
        fetchPage: { [unowned self] currentPage, _ in
            let result = await fetchNextPage(currentPage: currentPage)
            return result
        })

    private let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = .init()

    init(searchPaginator: MessagePaginator? = nil, dependencies: Dependencies = .init()) {
        AppLogger.logTemporarily(message: "SearchModel init", category: .search)
        self.searchPaginator = searchPaginator
        self.dependencies = dependencies
        setUpPaginatorCallback()
        setUpBindings()
        initialiseMailbox()
    }

    deinit {
        AppLogger.logTemporarily(message: "SearchModel deinit", category: .search)
    }

    private func setUpPaginatorCallback() {
        paginatorCallback.delegate = { [weak self] in
            guard let self else { return }
            Task {
                AppLogger.log(message: "search paginator callback", category: .search)
                await self.refreshMailboxItems()
            }
        }
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
            searchPaginator?.handle().disconnect()
            await paginatedDataSource.resetToInitialState()

            let result = await dependencies.searchProtocol.paginateSearch(
                session: dependencies.appContext.userSession,
                options: .init(query: query),
                callback: paginatorCallback
            )

            switch result {
            case .ok(let searchPaginator):
                self.searchPaginator = searchPaginator
                await paginatedDataSource.fetchInitialPage()
            case .error(let error):
                AppLogger.log(error: error, category: .search)
            }
        }
    }

    private func fetchNextPage(currentPage: Int) async -> PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult {
        let searchPaginator = searchPaginator.unsafelyUnwrapped
        switch await searchPaginator.reload() {
        case .ok(let messages):
            let items = mailboxItems(messages: messages)
            let result = PaginatedListDataSource<MailboxItemCellUIModel>.NextPageResult(
                newItems: items,
                isLastPage: !searchPaginator.hasNextPage()
            )
            AppLogger.log(message: "page \(currentPage) returned \(result.newItems.count) items, isLastPage: \(result.isLastPage)", category: .search)
            return result
        case .error(let error):
            AppLogger.log(error: error, category: .search)
            return .init(newItems: paginatedDataSource.state.items, isLastPage: true)
        }
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
        guard let searchPaginator else { return }
        switch await searchPaginator.reload() {
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
        let modifier = selectionMode.selectionModifier
        let action = isSelected ? modifier.addMailboxItem : modifier.removeMailboxItem
        action(item.toSelectedItem())
    }

    func onMailboxItemStarChange(item: MailboxItemCellUIModel, isStarred: Bool) {
        // TODO: is falls in the scope of actions
    }

    @MainActor
    func onMailboxItemAttachmentTap(attachmentId: ID, for item: MailboxItemCellUIModel) {
        guard !selectionMode.selectionState.hasItems, let mailbox else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        state.attachmentPresented = AttachmentViewConfig(id: attachmentId, mailbox: mailbox)
    }

    func onMailboxItemAction(_ action: Action, itemIds: [ID]) {
        // TODO: is falls in the scope of actions
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
        let searchProtocol: SearchProtocol = SearchWrapper()
    }
}

struct SearchWrapper: SearchProtocol {

    func paginateSearch(session: MailUserSession, options: SearchOptions, callback: any LiveQueryCallback) async -> PaginateSearchResult {
        await proton_app_uniffi.paginateSearch(session: session, options: .init(keywords: options.query), callback: callback)
    }
}
