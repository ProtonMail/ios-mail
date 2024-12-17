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
import InboxDesignSystem
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

struct MailboxItemsListView<EmptyView: View>: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    @State var config: MailboxItemsListViewConfiguration
    @ViewBuilder let emptyView: EmptyView
    @ObservedObject private(set) var selectionState: SelectionModeState

    // pull to refresh
    @State private var listPullOffset: CurrentValueSubject<CGFloat, Never> = .init(0.0)
    private var listPullOffsetPublisher: AnyPublisher<CGFloat, Never> {
        listPullOffset.eraseToAnyPublisher()
    }

    init(
        config: MailboxItemsListViewConfiguration,
        @ViewBuilder emptyView: () -> EmptyView
    ) {
        self._config = State(initialValue: config)
        self.emptyView = emptyView()
        self.selectionState = config.selectionState
    }

    var body: some View {
        ZStack {
            listView
            if selectionState.hasItems {
                mailboxActionBarView
            }
        }
    }

    private var listView: some View {
        PaginatedListView(
            dataSource: config.dataSource,
            emptyListView: { emptyView },
            cellView: { index, item in
                cellView(index: index, item: item)
            },
            onScrollEvent: { event in
                switch event {
                case .onChangeOffset(let offset):
                    self.listPullOffset.send(offset)
                }
            }
        )
        .listStyle(.plain)
        .introspect(.list, on: .iOS(.v17, .v18)) { collectionView in
            guard
                config.listEventHandler != nil,
                (collectionView.refreshControl as? ProtonRefreshControl) == nil
            else { return }
            let protonRefreshControl = ProtonRefreshControl(listPullOffset: listPullOffsetPublisher) {
                await config.listEventHandler?.pullToRefresh?()
            }
            collectionView.refreshControl = protonRefreshControl
            protonRefreshControl.tintColor = .clear
        }
        .listScrollObservation(onEventAtTopChange: { newValue in
            config.listEventHandler?.listAtTop?(newValue)
        })
        .sensoryFeedback(trigger: selectionState.selectedItems) { oldValue, newValue in
            oldValue.count != newValue.count ? .selection : nil
        }
    }

    private func cellView(index: Int, item: MailboxItemCellUIModel) -> some View {
        VStack {
            MailboxItemCell(
                uiModel: item,
                isParentListSelectionEmpty: !selectionState.hasItems,
                onEvent: { config.cellEventHandler?.onCellEvent($0, item) }
            )
            .accessibilityElementGroupedVoiceOver(value: voiceOverValue(for: item))
            .accessibilityIdentifier("\(MailboxListViewIdentifiers.listCell)\(index)")
            .mailboxSwipeActions(
                leadingSwipe: config.swipeActions?.leadingSwipe() ?? .none,
                trailingSwipe: config.swipeActions?.trailingSwipe() ?? .none,
                isSwipeEnabled: !selectionState.hasItems,
                mailboxItem: item
            ) { action, itemId in
                config.cellEventHandler?.onSwipeAction?(action, itemId)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(
            .init(top: DS.Spacing.tiny, leading: DS.Spacing.tiny, bottom: DS.Spacing.tiny, trailing: 0)
        )
        .listRowSeparator(.hidden)
        .compositingGroup()
        .clipShape(
            .rect(
                topLeadingRadius: 20,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
        )
        .background(DS.Color.Background.norm) // cell background color after clipping
    }

    private func voiceOverValue(for item: MailboxItemCellUIModel) -> String {
        let unread = item.isRead ? "" : L10n.Mailbox.VoiceOver.unread.string
        let expiration = item.expirationDate?.toExpirationDateUIModel?.text.string ?? ""
        let attachments = item.attachmentsUIModel.count > 0
        ? L10n.Mailbox.VoiceOver.attachments(count: item.attachmentsUIModel.count).string
        : ""
        let value: String = """
        \(unread)
        \(item.emails).
        \(item.subject).
        \(item.date.mailboxVoiceOverSupport()).
        \(expiration).
        \(item.snoozeDate ?? "").
        \(attachments)
        """
        return value
    }

    private var mailboxActionBarView: some View {
        MailboxActionBarView(
            state: .initial,
            availableActions: .productionInstance,
            itemTypeForActionBar: config.itemTypeForActionBar,
            selectedItems: config.selectionState.selectedItemIDsReadOnlyBinding
        )
        .opacity(selectionState.hasItems ? 1 : 0)
        .offset(y: selectionState.hasItems ? 0 : 45 + 100)
        .animation(.selectModeAnimation, value: selectionState.hasItems)
    }
}

private struct MailboxListViewIdentifiers {
    static let listCell = "mailbox.list.cell"
}

private extension SelectionModeState {

    var selectedItemIDsReadOnlyBinding: Binding<Set<MailboxSelectedItem>> {
        Binding(
            get: { [weak self] in self?.selectedItems ?? [] },
            set: { _ in }
        )
    }

}

#Preview {
    struct Container: View {
        let userSettings = UserSettings()

        let dataSource = PaginatedListDataSource<MailboxItemCellUIModel>(pageSize: 20) { currentPage, pageSize in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            let items = MailboxItemCellUIModel.testData()
            let isLastPage = (currentPage+1) * pageSize > items.count
            let range = currentPage * pageSize..<min(items.count, (currentPage+1) * pageSize)
            return .init(newItems: Array(items[range]), isLastPage: isLastPage)
        }

        var body: some View {
            MailboxItemsListView(
                config: makeConfiguration(),
                emptyView: { Text("MAILBOX IS EMPTY".notLocalized) }
            )
            .task {
                await dataSource.fetchInitialPage()
            }
            .environmentObject(userSettings)
        }

        func makeConfiguration() -> MailboxItemsListViewConfiguration {
            let selectionState = SelectionModeState()

            return .init(
                dataSource: dataSource,
                selectionState: selectionState,
                itemTypeForActionBar: .conversation,
                swipeActions: .init(leadingSwipe: { .toggleReadStatus }, trailingSwipe: { .moveToTrash })
            )
        }
    }
    return Container()
}
