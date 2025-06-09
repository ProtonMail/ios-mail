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
            AvatarCheckboxView(isSelected: false, avatar: uiModel.avatar, onDidChangeSelection: { _ in })
                .square(size: 40)
            VStack(spacing: DS.Spacing.compact) {
                senderRow
                previewRow
            }
        }
        .padding(.horizontal, DS.Spacing.large)
    }

    private var previewRow: some View {
        Text(uiModel.recipients)
            .font(.caption)
            .fontWeight(uiModel.isRead ? .regular : .bold)
            .foregroundStyle(uiModel.isRead ? DS.Color.Text.hint : DS.Color.Text.norm)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier(CollapsedMessageCellIdentifiers.preview)
    }

    private var senderRow: some View {
        HStack(spacing: DS.Spacing.small) {
            Text(uiModel.sender)
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
    let recipients: String
    let isRead: Bool
    let avatar: AvatarUIModel
}

#Preview {
    VStack(spacing: 0) {
        CollapsedMessageCell(
            uiModel: .init(
                sender: "Martha",
                date: .now,
                recipients: "john@gmail.com",
                isRead: true,
                avatar: .init(info: .init(initials: "Ba", color: .blue), type: .sender(params: .init()))
            ), isFirstCell: true, onTap: {})
        CollapsedMessageCell(
            uiModel: .init(
                sender: "john@gmail.com",
                date: .now,
                recipients: "martha@proton.me",
                isRead: false,
                avatar: .init(info: .init(initials: "De", color: .yellow), type: .sender(params: .init()))
            ), onTap: {})
        CollapsedMessageCell(
            uiModel: .init(
                sender: "Martha",
                date: .now,
                recipients: "john@gmail.com",
                isRead: true,
                avatar: .init(info: .init(initials: "Pr", color: .green), type: .sender(params: .init()))
            ), onTap: {})
    }
}

private struct CollapsedMessageCellIdentifiers {
    static let senderName = "detail.cell.collapsed.sender.name"
    static let preview = "detail.cell.collapsed.preview"
    static let dateText = "detail.cell.collapsed.date"
}
