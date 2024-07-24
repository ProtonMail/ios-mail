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

import DesignSystem
import SwiftUI

struct MailboxListView: View {
    @ObservedObject private var model: MailboxModel
    @State private var didAppearBefore = false

    init(model: MailboxModel) {
        self.model = model
    }

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                loadingView
            case .empty:
                MailboxEmptyView()
            case .data(let mailboxItems):
                mailboxItemsListView(mailboxItems: mailboxItems)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(trigger: model.selectionMode.selectedItems) { oldValue, newValue in
            oldValue.count != newValue.count ? .selection : nil
        }
        .task {
            guard !didAppearBefore else { return }
            didAppearBefore = true
            await model.onViewDidAppear()
        }
    }
}

extension MailboxListView {

    private var loadingView: some View {
        ProgressView()
    }

    private func mailboxItemsListView(mailboxItems: [MailboxItemCellUIModel]) -> some View {
        List {
            UnreadFilterBarView(isSelected: $model.isUnreadSelected, unread: model.unreadItemsCount)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .removeViewIf(model.unreadItemsCount < 1)

            ForEach(Array(mailboxItems.enumerated()), id: \.1.id) { index, item in
                VStack {
                    MailboxItemCell(
                        uiModel: item,
                        isParentListSelectionEmpty: !model.selectionMode.hasSelectedItems,
                        onEvent: { [weak model] event in
                            switch event {
                            case .onTap:
                                model?.onMailboxItemTap(item: item)
                            case .onLongPress:
                                model?.onLongPress(mailboxItem: item)
                            case .onSelectedChange(let isSelected):
                                model?.onMailboxItemSelectionChange(item: item, isSelected: isSelected)
                            case .onStarredChange(let isStarred):
                                model?.onMailboxItemStarChange(item: item, isStarred: isStarred)
                            case .onAttachmentTap(let attachmentId):
                                model?.onMailboxItemAttachmentTap(attachmentId: attachmentId, for: item)
                            }
                        }
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("\(MailboxListViewIdentifiers.listCell)\(index)")
                    .mailboxSwipeActions(
                        isSelectionModeOn: model.selectionMode.hasSelectedItems,
                        itemId: item.id,
                        systemFolder: model.selectedMailbox.systemFolder,
                        isItemRead: item.isRead,
                        onTapAction: model.onMailboxItemAction(_:itemIds:)
                    )

                    Spacer().frame(height: DS.Spacing.tiny)
                }
                .listRowInsets(
                    .init(top: 0, leading: DS.Spacing.tiny, bottom: 0, trailing: 0)
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
        }
        .listStyle(.plain)
    }
}

#Preview {
    let route: AppRouteState = .init(route: .mailbox(selectedMailbox: .inbox))
    let dummySettings = EmptyPMMailSettings()

    return MailboxListView(model: .init(
        state: .empty, // .data(PreviewData.mailboxConversations)
        mailSettings: dummySettings,
        appRoute: route
    ))
}

private struct MailboxListViewIdentifiers {
    static let listCell = "mailbox.list.cell"
}
