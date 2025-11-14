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
import InboxCoreUI
import ProtonUIFoundations
import SwiftUI

struct PaginatedListView<
    Item: Hashable & Identifiable & Sendable,
    HeaderView: View,
    EmptyListView: View,
    CellView: View
>: View {
    @EnvironmentObject private var loadingBarPresenter: LoadingBarPresenter
    @ObservedObject private var dataSource: PaginatedListDataSource<Item>
    private var headerView: () -> HeaderView?
    private var emptyListView: () -> EmptyListView
    private var cellView: (_ index: Int, Item) -> CellView
    private var viewState: PaginatedListViewState {
        dataSource.state.viewState
    }
    private var onScrollEvent: ((_ event: ListScrollOffsetTrackerView.ScrollEvent) -> Void)?

    @State private var listRealTopOffset: CGFloat = 0

    init(
        dataSource: PaginatedListDataSource<Item>,
        headerView: @escaping () -> HeaderView?,
        emptyListView: @escaping () -> EmptyListView,
        cellView: @escaping (Int, Item) -> CellView,
        onScrollEvent: ((_ event: ListScrollOffsetTrackerView.ScrollEvent) -> Void)? = nil
    ) {
        self.dataSource = dataSource
        self.headerView = headerView
        self.emptyListView = emptyListView
        self.cellView = cellView
        self.onScrollEvent = onScrollEvent
    }

    var body: some View {
        switch viewState {
        case .fetchingInitialPage:
            MailboxSkeletonView()
        case .data(let type):
            ZStack(alignment: .top) {
                LoadingBar(isLoading: loadingBarPresenter.isVisible)
                    .zIndex(1)
                dataStateView.overlay {
                    if type == .noItems {
                        emptyListView()
                    }
                }
            }
        }
    }

    private var dataStateView: some View {
        List {
            ListScrollOffsetTrackerView(listTopOffset: listRealTopOffset) { event in
                onScrollEvent?(event)
            }

            headerView()?
                .listRowBackground(Color.clear)

            ForEachEnumerated(dataSource.state.items, id: \.element.id) { item, index in
                cellView(index, item)
                    .onAppear {
                        if item == dataSource.state.items.last {
                            dataSource.fetchNextPageIfNeeded()
                        }
                    }
            }

            if viewState.showBottomSpinner {
                HStack {
                    ProtonSpinner()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(.clear)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .animation(.default, value: dataSource.state.items)
        .environment(\.defaultMinListRowHeight, 0)
        .readLayoutData(
            coordinateSpace: .global,
            onChange: { data in
                listRealTopOffset = data.frameInCoordinateSpace.minY
            })
    }
}

enum PaginatedListViewState: Equatable {
    case fetchingInitialPage
    case data(Data)

    enum Data: Equatable {
        case items(isFetchingNextPage: Bool)
        case noItems
    }

    var showBottomSpinner: Bool {
        switch self {
        case .fetchingInitialPage, .data(.noItems):
            false
        case .data(.items(let isFetchingNextPage)):
            isFetchingNextPage
        }
    }
}

#Preview {
    struct PreviewListItem: Hashable, Identifiable {
        var id: Int
    }

    @MainActor
    final class Model: Sendable {
        var currentPage = 0
        let pageSize = 20
        let subject: PassthroughSubject<PaginatedListUpdate<PreviewListItem>, Never> = .init()
        lazy var dataSource = PaginatedListDataSource<PreviewListItem>(
            fetchMore: { [weak self] isFirstPage in Task { await self?.nextPage(isFirstPage: isFirstPage) } }
        )

        private func nextPage(isFirstPage: Bool) async {
            try? await Task.sleep(for: .seconds(2))
            let newItems = Array(currentPage * pageSize..<(currentPage + 1) * pageSize)
            subject.send(
                .init(
                    isLastPage: currentPage == 3,
                    value: .append(
                        items: newItems.map { PreviewListItem(id: $0) }
                    )
                )
            )
            currentPage += 1
        }
    }

    struct WrapperView: View {
        let model = Model()

        var body: some View {
            PaginatedListView(
                dataSource: model.dataSource,
                headerView: {
                    Text("Numbered cells".notLocalized)
                        .bold()
                },
                emptyListView: {
                    Text("List is Empty".notLocalized)
                },
                cellView: { index, item in
                    Text("cell \(item.id)".notLocalized)
                }
            )
            .listStyle(.plain)
            .task { model.dataSource.fetchInitialPage() }
        }
    }

    return WrapperView()
}
