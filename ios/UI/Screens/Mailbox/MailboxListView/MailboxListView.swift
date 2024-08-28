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
    @Binding private var isListAtTop: Bool

    init(isListAtTop: Binding<Bool>, model: MailboxModel) {
        self._isListAtTop = isListAtTop
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
        .onChange(of: model.selectedMailbox) { _, _ in
            self.isListAtTop = true
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
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(DS.Color.Background.norm)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())

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
                    .accessibilityElementGroupedVoiceOver(value: voiceOverValue(for: item))
                    .accessibilityIdentifier("\(MailboxListViewIdentifiers.listCell)\(index)")

                    .mailboxSwipeActions(
                        isSelectionModeOn: model.selectionMode.hasSelectedItems,
                        mailboxItemId: item.id,
                        systemFolder: model.selectedMailbox.systemFolder,
                        isItemRead: item.isRead,
                        onTapAction: model.onMailboxItemAction(_:itemIds:)
                    )

                    Spacer().frame(height: DS.Spacing.tiny)
                }
                .listRowBackground(Color.clear)
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
        .listScrollObservation(onEventAtTopChange: { newValue in
            isListAtTop = newValue
        })
    }

    private func voiceOverValue(for item: MailboxItemCellUIModel) -> String {
        let unread = item.isRead ? "" : L10n.Mailbox.VoiceOver.unread.string
        let expiration = item.expirationDate?.toExpirationDateUIModel?.text.string ?? ""
        let attachments = item.attachmentsUIModel.count > 0
        ? L10n.Mailbox.VoiceOver.attachments(count: item.attachmentsUIModel.count).string
        : ""
        let value: String = """
        \(unread)
        \(item.senders).
        \(item.subject).
        \(item.date.mailboxVoiceOverSupport()).
        \(expiration).
        \(item.snoozeDate ?? "").
        \(attachments)
        """
        return value
    }
}

#Preview {
    let route: AppRouteState = .init(route: .mailbox(selectedMailbox: .inbox))

    return MailboxListView(
        isListAtTop: .constant(true),
        model: .init(
            state: .empty,
            mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
            appRoute: route
        )
    )
}

private struct MailboxListViewIdentifiers {
    static let listCell = "mailbox.list.cell"
}
