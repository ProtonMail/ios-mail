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

struct MailboxItemCell: View {
    @Environment(\.sizeCategory) var sizeCategory
    @State private(set) var isPressed: Bool = false

    let uiModel: MailboxItemCellUIModel
    let isParentListSelectionEmpty: Bool
    let onEvent: (MailboxItemCellEvent) -> Void

    private var textColor: Color {
        uiModel.isRead ? DS.Color.Text.weak : DS.Color.Text.norm
    }

    private var labelLeadingPadding: CGFloat {
        uiModel.labelUIModel.isEmpty ? 0 : DS.Spacing.small
    }

    var body: some View {
        HStack(spacing: DS.Spacing.large) {
            avatarView
            mailboxItemContentView
        }
        .padding(.horizontal, DS.Spacing.large)
        .padding(.vertical, DS.Spacing.medium)
        .background(uiModel.isSelected || isPressed ? DS.Color.Brand.minus30 : DS.Color.Background.norm)
    }
}

extension MailboxItemCell {

    private var avatarView: some View {
        AvatarCheckboxView(
            isSelected: uiModel.isSelected,
            avatar: uiModel.avatar,
            onDidChangeSelection: { onEvent(.onSelectedChange(isSelected: $0)) }
        )
        .square(size: 40)
    }

    private var mailboxItemContentView: some View {
        VStack(spacing: DS.Spacing.compact) {
            senderRowView
            VStack(spacing: DS.Spacing.small) {
                subjectRowView
                expirationRowView
                snoozedRowView
            }
            attachmentRowView
            labelsRowView
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEvent(.onTap)
        }
        .onLongPressGesture(perform: {
            onEvent(.onLongPress)
        }, onPressingChanged: {
            guard isParentListSelectionEmpty else { return }
            isPressed = $0
        })
    }

    private var senderRowView: some View {
        HStack(spacing: DS.Spacing.small) {
            replyIcons
            Text(uiModel.emails)
                .font(.callout)
                .fontWeight(uiModel.isRead ? .regular : .bold)
                .lineLimit(1)
                .foregroundColor(textColor)
                .accessibilityIdentifier(MailboxItemCellIdentifiers.senderText)
            ProtonOfficialBadgeView()
                .removeViewIf(!uiModel.isSenderProtonOfficial)
            MailboxConversationMessageCountView(isRead: uiModel.isRead, messagesCount: uiModel.messagesCount)
            Spacer()
            Text(uiModel.date.mailboxFormat())
                .font(.caption)
                .fontWeight(uiModel.isRead ? .regular : .bold)
                .foregroundColor(uiModel.isRead ? DS.Color.Text.weak : DS.Color.Text.norm)
                .accessibilityIdentifier(MailboxItemCellIdentifiers.dateText)
        }
    }

    private var subjectRowView: some View {
        HStack(spacing: DS.Spacing.small) {
            locationView

            Text(uiModel.subject)
                .font(.subheadline)
                .fontWeight(uiModel.isRead ? .regular : .semibold)
                .lineLimit(1)
                .foregroundColor(textColor)
                .layoutPriority(1)
                .accessibilityIdentifier(MailboxItemCellIdentifiers.subjectText)

            Spacer()
            Image(uiModel.isStarred ? DS.Icon.icStarFilledStrong : DS.Icon.icStarStrong)
                .resizable()
                .square(size: 16)
                .foregroundColor(uiModel.isStarred ? DS.Color.Star.selected : DS.Color.Star.default)
                .onTapGesture {
                    onEvent(.onStarredChange(isStarred: !uiModel.isStarred))
                }
                .accessibilityIdentifier(MailboxItemCellIdentifiers.starIcon)
        }
        .frame(height: 21.0)
    }

    @ViewBuilder
    private var locationView: some View {
        if let icon = uiModel.locationIcon {
            Image(icon)
                .resizable()
                .square(size: 20)
                .foregroundColor(DS.Color.Text.weak)
        }
    }

    @ViewBuilder
    private var replyIcons: some View {
        if uiModel.replyIcons.shouldShowIcon {
            HStack(spacing: DS.Spacing.tiny) {
                if uiModel.replyIcons.shouldShowRepliedIcon {
                    imageForReplyIcon(imageResource: DS.Icon.icReply)
                }
                if uiModel.replyIcons.shouldShowRepliedAllIcon {
                    imageForReplyIcon(imageResource: DS.Icon.icReplyAll)
                }
                if uiModel.replyIcons.shouldShowForwardedIcon {
                    imageForReplyIcon(imageResource: DS.Icon.icForward)
                }
            }
        }
    }

    private func imageForReplyIcon(imageResource: ImageResource) -> some View {
        Image(imageResource)
            .resizable()
            .square(size: 20)
            .foregroundColor(DS.Color.Text.weak)
    }

    @ViewBuilder
    private var expirationRowView: some View {
        if let uiModel = uiModel.expirationDate?.toExpirationDateUIModel {
            TimelineView(.everyMinute) { context in
                Text(uiModel.text)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(uiModel.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var snoozedRowView: some View {
        if let snoozeDate = uiModel.snoozeDate {
            Text(snoozeDate)
                .font(.subheadline)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Notification.warning)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var attachmentRowView: some View {
        if !uiModel.attachmentsUIModel.isEmpty {
            AttachmentsView(
                uiModel: uiModel.attachmentsUIModel,
                isAttachmentHighlightEnabled: isParentListSelectionEmpty,
                onTapEvent: {
                    onEvent(.onAttachmentTap(attachmentID: $0))
                }
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(MailboxItemCellIdentifiers.attachments)
        }
    }

    @ViewBuilder
    private var labelsRowView: some View {
        if !uiModel.labelUIModel.labelModels.isEmpty {
            OneLineLabelsListView(labels: uiModel.labelUIModel.labelModels)
        }
    }
}

@Observable
final class MailboxItemCellUIModel: Identifiable, Sendable {
    let id: ID
    let conversationID: ID
    let type: MailboxItemType
    let avatar: AvatarUIModel
    let emails: String
    let subject: String
    let date: Date
    let locationIcon: ImageResource?
    let isRead: Bool
    let isStarred: Bool
    let isSelected: Bool
    let isSenderProtonOfficial: Bool
    let messagesCount: UInt64
    let labelUIModel: MailboxLabelUIModel
    let attachmentsUIModel: [AttachmentCapsuleUIModel]
    let replyIcons: ReplyIconsUIModel
    let expirationDate: Date?
    let snoozeDate: String?

    init(
        id: ID,
        conversationID: ID,
        type: MailboxItemType,
        avatar: AvatarUIModel,
        emails: String,
        subject: String,
        date: Date,
        locationIcon: ImageResource?,
        isRead: Bool,
        isStarred: Bool,
        isSelected: Bool,
        isSenderProtonOfficial: Bool,
        messagesCount: UInt64,
        labelUIModel: MailboxLabelUIModel = .init(),
        attachmentsUIModel: [AttachmentCapsuleUIModel] = [],
        replyIcons: ReplyIconsUIModel = .init(),
        expirationDate: Date?,
        snoozeDate: Date?
    ) {
        self.id = id
        self.conversationID = conversationID
        self.type = type
        self.avatar = avatar
        self.emails = emails
        self.subject = subject
        self.date = date
        self.locationIcon = locationIcon
        self.isRead = isRead
        self.isStarred = isStarred
        self.isSelected = isSelected
        self.isSenderProtonOfficial = isSenderProtonOfficial
        self.messagesCount = messagesCount
        self.labelUIModel = labelUIModel
        self.attachmentsUIModel = attachmentsUIModel
        self.replyIcons = replyIcons
        self.expirationDate = expirationDate

        var snoozeTime: String? = nil
        if let snoozeDate {
            snoozeTime = L10n.Mailbox.Item.snoozedTill(value: snoozeDate.mailboxSnoozeFormat()).string
        }
        self.snoozeDate = snoozeTime
    }
}

extension MailboxItemCellUIModel: Hashable {
    static func == (lhs: MailboxItemCellUIModel, rhs: MailboxItemCellUIModel) -> Bool {
        lhs.type == rhs.type 
        && lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(type)
    }
}

struct ReplyIconsUIModel {
    let shouldShowRepliedIcon: Bool
    let shouldShowRepliedAllIcon: Bool
    let shouldShowForwardedIcon: Bool

    init(
        shouldShowRepliedIcon: Bool = false,
        shouldShowRepliedAllIcon: Bool = false,
        shouldShowForwardedIcon: Bool = false
    ) {
        self.shouldShowRepliedIcon = shouldShowRepliedIcon
        self.shouldShowRepliedAllIcon = shouldShowRepliedAllIcon
        self.shouldShowForwardedIcon = shouldShowForwardedIcon
    }

    var shouldShowIcon: Bool {
        shouldShowRepliedIcon || shouldShowRepliedAllIcon || shouldShowForwardedIcon
    }
}

enum MailboxItemCellEvent {
    case onTap
    case onLongPress
    case onSelectedChange(isSelected: Bool)
    case onStarredChange(isStarred: Bool)
    case onAttachmentTap(attachmentID: ID)
}

#Preview {
    VStack {
        MailboxItemCell(uiModel: MailboxItemCellUIModel.proton1, isParentListSelectionEmpty: true, onEvent: { _ in })

        MailboxItemCell(
            uiModel: .init(
                id: .random(),
                conversationID: .random(),
                type: .message,
                avatar: .init(info: .init(initials: "FE", color: .yellow), type: .sender(params: .init())),
                emails: "FedEx",
                subject: "Your package",
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                locationIcon: DS.Icon.icInbox,
                isRead: false,
                isStarred: true,
                isSelected: false,
                isSenderProtonOfficial: false,
                messagesCount: 3,
                labelUIModel: .init(labelModels: [
                    LabelUIModel(labelId: .init(value: 0), text: "Offer lst minute for me and for you", color: .purple)
                ]),
                attachmentsUIModel: [
                    .init(id: .init(value: 1), icon: DS.Icon.icFileTypeIconPdf, name: "#34JE3KLP.pdf")
                ],
                replyIcons: .init(shouldShowForwardedIcon: true),
                expirationDate: .now,
                snoozeDate: .now + 500
            ),
            isParentListSelectionEmpty: true,
            onEvent: { _ in }
        )

        MailboxItemCell(
            uiModel: .init(
                id: .random(),
                conversationID: .random(),
                type: .message,
                avatar: .init(info: .init(initials: "MA", color: .cyan), type: .sender(params: .init())),
                emails: "Mary, Elijah Wood, wiseman@pm.me",
                subject: "Summer holidays pictures and more!",
                date: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
                locationIcon: nil,
                isRead: true,
                isStarred: true,
                isSelected: false,
                isSenderProtonOfficial: true,
                messagesCount: 12,
                labelUIModel: MailboxLabelUIModel(
                    labelModels: [.init(labelId: .init(value: 0), text: "Read later", color: .green)] + LabelUIModel.random(num: 3)),
                attachmentsUIModel: [
                    .init(id: .init(value: 1), icon: DS.Icon.icFileTypeIconPdf, name: "today_meeting_minutes.doc"),
                    .init(id: .init(value: 2), icon: DS.Icon.icFileTypeIconPdf, name: "appendix1.pdf"),
                    .init(id: .init(value: 3), icon: DS.Icon.icFileTypeIconPdf, name: "appendix2.pdf")
                ],
                replyIcons: .init(shouldShowRepliedAllIcon: true),
                expirationDate: .now + 500,
                snoozeDate: .now + 55000
            ),
            isParentListSelectionEmpty: true,
            onEvent: { _ in }
        )

        MailboxItemCell(uiModel: MailboxItemCellUIModel.proton2, isParentListSelectionEmpty: true, onEvent: { _ in })
    }
}

private struct MailboxItemCellIdentifiers {
    static let senderText = "cell.senderText"
    static let subjectText = "cell.subjectText"
    static let starIcon = "cell.starIcon"
    static let dateText = "cell.dateText"
    static let attachments = "cell.attachments"
}
