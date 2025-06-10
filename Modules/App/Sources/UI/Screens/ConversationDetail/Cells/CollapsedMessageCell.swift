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

import InboxDesignSystem
import SwiftUI

struct CollapsedMessageCell: View {
    private let uiModel: CollapsedMessageCellUIModel
    private let onTap: () -> Void

    /**
     Determines how the horizontal edges of the card are rendered to give visual
     continuation to the list (only visible in landscape mode).
     */
    private let isFirstCell: Bool

    init(
        uiModel: CollapsedMessageCellUIModel,
        isFirstCell: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.uiModel = uiModel
        self.isFirstCell = isFirstCell
        self.onTap = onTap
    }

    var body: some View {
        ZStack(alignment: .top) {
            messageCardTopView
            messageDataView
                .padding(.bottom, DS.Spacing.large)
                .overlay { borderOnTheSides(show: isFirstCell) }
                .padding(.top, DS.Spacing.large)
        }
        .overlay { borderOnTheSides(show: !isFirstCell) }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private func borderOnTheSides(show: Bool) -> some View {
        EdgeBorder(
            width: 1,
            edges: [.leading, .trailing]
        )
        .foregroundColor(DS.Color.Border.strong)
        .removeViewIf(!show)
    }

    private var messageCardTopView: some View {
        MessageCardTopView(cornerRadius: DS.Radius.extraLarge, hasShadow: true)
    }

    private var messageDataView: some View {
        HStack(alignment: .top, spacing: DS.Spacing.large) {
            boxView
            VStack(spacing: DS.Spacing.compact) {
                senderRow
                recipientsRow
            }
        }
        .padding(.horizontal, DS.Spacing.large)
    }

    // FIXME: - Change name
    @ViewBuilder
    private var boxView: some View {
        if uiModel.isDraft {
            Image(DS.Icon.icPenSquare)
                .resizable()
                .square(size: 20)
                .foregroundStyle(DS.Color.Text.weak)
                .square(size: 40)
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.large)
                        .stroke(DS.Color.Border.strong)
                }
        } else {
            AvatarCheckboxView(isSelected: false, avatar: uiModel.avatar, onDidChangeSelection: { _ in })
                .square(size: 40)
        }
    }

    private var recipientsRow: some View {
        recipients
            .font(.caption)
            .fontWeight(uiModel.isRead ? .regular : .bold)
            .foregroundStyle(uiModel.isRead ? DS.Color.Text.hint : DS.Color.Text.norm)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier(CollapsedMessageCellIdentifiers.preview)
    }

    private var recipients: Text {
        if uiModel.isDraft {
            let emptyPlaceholder = "\(L10n.MessageDetails.to.string): ..."
            return Text(
                uiModel.recipients.isEmpty ? emptyPlaceholder : uiModel.recipients.recipientsUIRepresentation
            )
        } else {
            return Text(uiModel.recipients.recipientsUIRepresentation)
        }
    }

    private var sender: Text {
        let senderText = Text(uiModel.sender)
            .foregroundColor(uiModel.isRead ? DS.Color.Text.weak : DS.Color.Text.norm)
        return uiModel.isDraft ? senderText + draft : senderText
    }

    private var draft: Text {
        Text(" (Draft)")
            .foregroundStyle(DS.Color.Notification.error)
    }

    private var senderRow: some View {
        HStack(spacing: DS.Spacing.small) {
            sender
                .font(.subheadline)
                .fontWeight(uiModel.isRead ? .regular : .bold)
                .lineLimit(1)
                .foregroundColor(uiModel.isRead ? DS.Color.Text.weak : DS.Color.Text.norm)
                .accessibilityIdentifier(CollapsedMessageCellIdentifiers.senderName)
            Spacer()
            Text(uiModel.date.mailboxFormat())
                .font(.caption)
                .fontWeight(uiModel.isRead ? .regular : .bold)
                .foregroundColor(uiModel.isRead ? DS.Color.Text.weak : DS.Color.Text.norm)
                .accessibilityIdentifier(CollapsedMessageCellIdentifiers.dateText)
        }
    }
}

struct CollapsedMessageCellUIModel {
    let sender: String
    let date: Date
    let recipients: [MessageDetail.Recipient]
    let isRead: Bool
    let isDraft: Bool
    let avatar: AvatarUIModel
}

#Preview {
    VStack(spacing: 0) {
        CollapsedMessageCell(
            uiModel: .init(
                sender: "Martha",
                date: .now,
                recipients: [
                    .init(name: "john@gmail.com", address: .empty, avatarInfo: .init(initials: .empty, color: .black))
                ],
                isRead: true,
                isDraft: false,
                avatar: .init(info: .init(initials: "Ba", color: .blue), type: .sender(params: .init()))
            ), isFirstCell: true, onTap: {})
        CollapsedMessageCell(
            uiModel: .init(
                sender: "john@gmail.com",
                date: .now,
                recipients: [
                    .init(name: "martha@proton.me", address: .empty, avatarInfo: .init(initials: .empty, color: .black))
                ],
                isRead: false,
                isDraft: false,
                avatar: .init(info: .init(initials: "De", color: .yellow), type: .sender(params: .init()))
            ), onTap: {})
        CollapsedMessageCell(
            uiModel: .init(
                sender: "Martha",
                date: .now,
                recipients: [
                    .init(name: "john@gmail.com", address: .empty, avatarInfo: .init(initials: .empty, color: .black))
                ],
                isRead: true,
                isDraft: false,
                avatar: .init(info: .init(initials: "Pr", color: .green), type: .sender(params: .init()))
            ), onTap: {})
    }
}

private struct CollapsedMessageCellIdentifiers {
    static let senderName = "detail.cell.collapsed.sender.name"
    static let preview = "detail.cell.collapsed.preview"
    static let dateText = "detail.cell.collapsed.date"
}
