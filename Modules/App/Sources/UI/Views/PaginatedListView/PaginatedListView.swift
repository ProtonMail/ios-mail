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
import SwiftUI

struct PaginatedListView<
    Item: Identifiable & Sendable,
    HeaderView: View,
    EmptyListView: View,
    CellView: View
>: View {
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
            dataStateView.overlay {
                if type == .placeholder {
                    emptyListView()
                }
            }
        }
    }

    private var dataStateView: some View {
        List {
            ListScrollOffsetTrackerView(listTopOffset: listRealTopOffset) { event in
                onScrollEvent?(event)
            }

            headerView()

            ForEachEnumerated(dataSource.state.items, id: \.element.id) { item, index in
                cellView(index, item)
            }

            if viewState.showBottomSpinner {
                HStack {
                    ProtonSpinner()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(.clear)
                        .onAppear {
                            Task { await dataSource.fetchNextPageIfNeeded() }
                        }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .environment(\.defaultMinListRowHeight, 0)
        .readLayoutData(coordinateSpace: .global, onChange: { data in
            listRealTopOffset = data.frameInCoordinateSpace.minY
        })
    }
}

enum PaginatedListViewState: Equatable {
    case fetchingInitialPage
    case data(Data)
    
    enum Data: Equatable {
        case items(isLastPage: Bool)
        case placeholder
    }
    
    var showBottomSpinner: Bool {
        switch self {
        case .fetchingInitialPage:
            true
        case .data(.items(let isLastPage)):
            !isLastPage
        case .data(.placeholder):
            false
        }
    }
}

#Preview {

    struct PreviewListItem: Identifiable {
        var id: Int
    }

    func fetchMockItems(page: Int, pageSize: Int) async -> PaginatedListDataSource<PreviewListItem>.NextPageResult {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        let newItems = Array(page * pageSize..<(page + 1) * pageSize)
        return .init(newItems: newItems.map { PreviewListItem(id: $0) }, isLastPage: page == 3)
    }

    let dataSource = PaginatedListDataSource<PreviewListItem>(pageSize: 20, fetchPage: fetchMockItems)

    return PaginatedListView(
        dataSource: dataSource,
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
    .task { await dataSource.fetchInitialPage() }
}
